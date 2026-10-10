#!/usr/bin/env python3
"""Check that the pr-explainer model is complete before any prose is written.

Usage: check-model.py <pr-N.json> [--section section.md] [--files names.txt] [--root DIR] [--lang ja]

--lang ja fails when a field the reader reads (gist, each `what`, focus text, new concepts, questions,
unverified reasons) is mostly not Japanese: outside code spans, fewer than 20% of its letters are kana or kanji. So a
report meant for a Japanese reader cannot ship in English, even with one Japanese word in it. A short quote of the
author's own words may stay in its language inside a Japanese sentence. --lang en fails a field that has Japanese
text outside code spans. Only the model fields are checked, not the finished report.

The model's optional "mode" is "author" (default) or "reviewer". A reviewer model must set "mode": "reviewer" and
have `claims`, `unmentioned` and `questions`; each `claims[].source` is `title`, `body` or `commit <sha>`, and each
`questions[].where` is a `path:line`; a `differs` or `partial` claim must cite a `path:line` (`base:path:line` for code the PR deleted); with --files every `unmentioned`
path must be a changed file, or a directory ending in `/` whose `count` equals the changed files under it that no other `unmentioned` entry lists. A
reviewer report is not a PR body: there is no size limit, only a note above 20000 characters of the linked text.

Fails on a missing key, an empty entry, or a placeholder ("...", TODO, TBD). With --section it
also compares the edges of the Mermaid fence in the section with `diagram.edges`, in both
directions; `from` and `to` in the model are the Mermaid node ids. Run it on the section after the
citations are linked: links add 30-60% to the length. A section with a verdict word
(SAFE, LOW RISK, MERGEABLE, "no impact", 影響なし) fails, and so does one over 45000 characters (the
whole PR body is limited to 65536, and the existing body counts too).
--files takes the output of `gh pr diff <n> --name-only`: every file must be covered by a `reading_order`
entry, either its exact path or a directory entry ending in `/`. --root checks that each
`diagram.edges[].evidence` (`path:line`) names a line that exists, and every directory entry's `count`
equals the number of changed files that really fall under it and no other entry lists.

Exit 0: model complete. Exit 1: at least one problem. Exit 2: usage or parse error.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re
import sys

PLACEHOLDER = re.compile(r"^\s*(\.\.\.|…|todo|tbd|placeholder|n/a|<.*>)?\s*$", re.IGNORECASE)
# Upper-case verdicts are matched as written (so `UNSAFE_x` and "safe" in prose pass); "no impact" in any case.
VERDICT = re.compile(r"\bSAFE\b|\bLOW RISK\b|\bMERGEABLE\b|影響なし|\b[Nn][Oo] impact\b")
MAX_SECTION = 45000
WARN_SECTION = 25000
WARN_REPORT = 20000
MAX_WHAT = 300
JA = re.compile(r"[\u3040-\u30ff\u4e00-\u9fff]")
MODES = ("author", "reviewer")
STATUS = ("matches", "partial", "differs", "not_in_diff", "not_checked")
WHY = ("core", "contract", "migration", "config", "tests", "docs", "mechanical")
EVIDENCE = re.compile(r"(?P<path>.+?):(?P<start>\d+)(?:-(?P<end>\d+))?")
DIAGRAM_TYPES = {"mermaid", "sequence", "data-flow", "architecture", "none"}

# key -> (kind, required fields per entry)
LISTS = {
    "reading_order": ("list", ("path", "what", "why")),
    "evidence": ("list", ("claim", "cmd", "output")),
    "unverified": ("list", ("claim", "why_not")),
}


def blank(value: object) -> bool:
    return not isinstance(value, str) or bool(PLACEHOLDER.match(value))


def reviewer_problems(model: dict) -> list[str]:
    problems: list[str] = []
    shapes = {
        "claims": ("claim", "source", "evidence"),
        "unmentioned": ("path", "what"),
        "questions": ("where", "ask"),
    }
    for key, fields in shapes.items():
        entries = model.get(key)
        if not isinstance(entries, list):
            problems.append(f"{key}: missing. A reviewer model needs it; use an empty list when there is nothing to say.")
            continue
        for i, entry in enumerate(entries):
            for field in fields:
                if not isinstance(entry, dict) or blank(entry.get(field)):
                    problems.append(f"{key}[{i}].{field}: empty or placeholder. Fill it in or drop the entry.")
            if key == "questions" and isinstance(entry, dict) and not EVIDENCE.fullmatch(str(entry.get("where", ""))):
                problems.append(f"questions[{i}].where: {entry.get('where')!r} is not a path:line.")
            if key == "claims" and isinstance(entry, dict):
                if not re.fullmatch(r"title|body|commit [0-9a-f]{7,40}", str(entry.get("source", ""))):
                    problems.append(f"claims[{i}].source: {entry.get('source')!r} is not title, body or commit <sha>.")
                if entry.get("status") not in STATUS:
                    problems.append(f"claims[{i}].status: {entry.get('status')!r} is not one of {', '.join(STATUS)}.")
                elif entry["status"] in ("differs", "partial") and not EVIDENCE.fullmatch(str(entry.get("evidence", "")).removeprefix("base:")):
                    problems.append(f"claims[{i}].evidence: a {entry['status']} claim cites a path:line in the diff, not {entry.get('evidence')!r}.")
            if key == "unmentioned" and isinstance(entry, dict) and str(entry.get("path", "")).endswith("/") \
                    and not (isinstance(entry.get("count"), int) and entry["count"] >= 1):
                problems.append(f"unmentioned[{i}]: a directory entry needs an integer `count` of the changed files under it.")
    return problems


CODE_SPAN = re.compile(r"`[^`]*`")
JA_SHARE = 0.2


def ja_share(text: str) -> float | None:
    """Share of kana and kanji among the letters outside code spans; None when there are no letters."""
    plain = CODE_SPAN.sub("", text)
    ja, ascii_letters = len(JA.findall(plain)), len(re.findall(r"[A-Za-z]", plain))
    return ja / (ja + ascii_letters) if ja + ascii_letters else None


def language_problems(model: dict, lang: str) -> list[str]:
    texts: list[tuple[str, object]] = [("gist", model.get("gist"))]
    for i, c in enumerate(model.get("new_concepts") or []):
        texts.append((f"new_concepts[{i}]", c))
    for i, e in enumerate(model.get("reading_order") or []):
        if not isinstance(e, dict):
            continue
        texts.append((f"reading_order[{i}].what", e.get("what")))
        for j, f in enumerate(e.get("focus") or []):
            if isinstance(f, dict):
                texts += [(f"reading_order[{i}].focus[{j}].what", f.get("what")), (f"reading_order[{i}].focus[{j}].how_to_check", f.get("how_to_check"))]
    for key, field in (("questions", "ask"), ("unmentioned", "what"), ("unverified", "why_not")):
        for i, e in enumerate(model.get(key) or []):
            if isinstance(e, dict):
                texts.append((f"{key}[{i}].{field}", e.get(field)))
    problems = []
    for label, t in texts:
        if not isinstance(t, str) or not t.strip():
            continue
        share = ja_share(t)
        if lang == "ja" and share is not None and share < JA_SHARE:
            problems.append(f"{label}: only {share:.0%} of its letters are Japanese ({t[:50]!r}...). Write it in Japanese; only a short quote of the author's words may stay in its language.")
        if lang == "en" and JA.search(CODE_SPAN.sub("", t)):
            problems.append(f"{label}: has Japanese text but the report language is English ({t[:50]!r}...).")
    return problems


def check_model(model: dict) -> list[str]:
    problems: list[str] = []
    mode = model.get("mode", "author")
    if mode not in MODES:
        problems.append(f"mode: {mode!r} is not one of {', '.join(MODES)}.")
    elif mode == "reviewer":
        problems.extend(reviewer_problems(model))
    elif any(k in model for k in ("claims", "unmentioned", "questions")):
        problems.append("claims, unmentioned or questions are present but mode is not \"reviewer\": set \"mode\": \"reviewer\" so the reviewer checks run.")
    if blank(model.get("gist")):
        problems.append("gist: write one sentence saying what the PR does now that it did not before.")
    for key, (_, fields) in LISTS.items():
        entries = model.get(key)
        if not isinstance(entries, list):
            problems.append(f"{key}: missing. Use an empty list when there is nothing to say.")
            continue
        for i, entry in enumerate(entries):
            for field in fields:
                if not isinstance(entry, dict) or blank(entry.get(field)):
                    problems.append(f"{key}[{i}].{field}: empty or placeholder. Fill it in or drop the entry.")
    if not model.get("reading_order"):
        problems.append("reading_order: empty. A PR with files has an order to read them in.")
    entries = model.get("reading_order") if isinstance(model.get("reading_order"), list) else []
    for i, entry in enumerate(entries):
        focus = entry.get("focus", []) if isinstance(entry, dict) else []
        if not isinstance(focus, list):
            problems.append(f"reading_order[{i}].focus: must be a list.")
            continue
        for j, item in enumerate(focus):
            for field in ("where", "what", "how_to_check"):
                if not isinstance(item, dict) or blank(item.get(field)):
                    problems.append(f"reading_order[{i}].focus[{j}].{field}: empty or placeholder. Name a place and a way to check it, or drop the focus.")
    for i, entry in enumerate(entries):
        if not isinstance(entry, dict):
            continue
        if entry.get("why") not in WHY:
            problems.append(f"reading_order[{i}].why: {entry.get('why')!r} is not one of {', '.join(WHY)}.")
        if isinstance(entry.get("what"), str) and len(entry["what"]) > MAX_WHAT:
            problems.append(f"reading_order[{i}].what: {len(entry['what'])} characters (limit {MAX_WHAT}). Say less, or split the entry.")
        if str(entry.get("path", "")).endswith("/") and not (isinstance(entry.get("count"), int) and entry["count"] >= 1):
            problems.append(f"reading_order[{i}]: a directory entry needs an integer `count` of the files it covers.")
    starred = sum(1 for e in entries if isinstance(e, dict) and e.get("focus"))
    if len(entries) >= 5 and starred * 2 > len(entries):
        print(f"note: {starred} of {len(entries)} entries are starred; when most have a star, none stands out.", file=sys.stderr)
    concepts = model.get("new_concepts")
    if not isinstance(concepts, list) or any(blank(c) for c in concepts):
        problems.append("new_concepts: must be a list of non-empty strings (empty list is fine).")
    cov = model.get("coverage")
    if not (isinstance(cov, dict) and all(isinstance(cov.get(k), int) for k in ("files_total", "files_opened", "files_partial"))):
        problems.append("coverage: needs integer files_total, files_opened and files_partial, so the body can say how much was read.")
    elif cov["files_opened"] > cov["files_total"]:
        problems.append("coverage: files_opened is larger than files_total.")
    elif cov["files_partial"] > cov["files_opened"]:
        problems.append("coverage: files_partial counts opened files read only in part, so it cannot exceed files_opened.")
    elif starred > cov["files_opened"]:
        problems.append(f"coverage: {starred} files are starred but only {cov['files_opened']} were opened. Do not star a file you did not read.")
    elif cov["files_opened"] * 2 < cov["files_total"]:
        print(f"note: only {cov['files_opened']} of {cov['files_total']} files were opened; the gist or the first line of \"Not verified\" should say so.", file=sys.stderr)
    diagram = model.get("diagram")
    if not isinstance(diagram, dict) or diagram.get("type") not in DIAGRAM_TYPES:
        problems.append(f"diagram.type: one of {sorted(DIAGRAM_TYPES)}.")
    elif diagram["type"] != "none":
        edges = diagram.get("edges")
        if not edges:
            problems.append("diagram.edges: empty. Draw nothing, or set type to none.")
        for i, edge in enumerate(edges or []):
            for field in ("from", "to", "evidence"):
                if not isinstance(edge, dict) or blank(edge.get(field)):
                    problems.append(f"diagram.edges[{i}].{field}: empty. An edge without a cited place is not drawn.")
    return problems


def coverage_problems(model: dict, files: list[str]) -> list[str]:
    """Every file belongs to its most specific entry (an exact path, else the longest directory); a directory's count must match."""
    entries = [c for c in model.get("reading_order", []) if isinstance(c, dict)]
    exact = {c["path"] for c in entries if not str(c.get("path", "")).endswith("/")}
    dirs = sorted((c for c in entries if str(c.get("path", "")).endswith("/")), key=lambda c: -len(c["path"]))
    owned: dict[str, list[str]] = {d["path"]: [] for d in dirs}
    problems: list[str] = []
    missing = []
    for f in files:
        if f in exact:
            continue
        owner = next((d for d in dirs if f.startswith(d["path"])), None)
        if owner is None:
            missing.append(f)
        else:
            owned[owner["path"]].append(f)
    for f in missing[:10]:
        problems.append(f"{f}: no `reading_order` entry covers this file. Add one, or a directory entry ending in `/`.")
    if len(missing) > 10:
        problems.append(f"... and {len(missing) - 10} more files without a `reading_order` entry.")
    for d in dirs:
        actual = len(owned[d["path"]])
        if isinstance(d.get("count"), int) and d["count"] != actual:
            sample = ", ".join(owned[d["path"]][:3])
            problems.append(f"{d['path']}: count is {d['count']} but {actual} changed files fall under it and no other entry lists them ({sample}...). Fix the count, or list the files that matter.")
    return problems


def missing_evidence(model: dict, root: pathlib.Path) -> list[str]:
    problems = []
    for i, edge in enumerate(model.get("diagram", {}).get("edges", [])):
        m = EVIDENCE.fullmatch(edge.get("evidence", ""))
        target = root / m["path"] if m else None
        if not m or not target.is_file():
            problems.append(f"diagram.edges[{i}].evidence: {edge.get('evidence')!r} is not a file:line that exists under {root}.")
        elif int(m["start"]) > len(target.read_text(errors="replace").splitlines()) or int(m["start"]) < 1:
            problems.append(f"diagram.edges[{i}].evidence: {m['path']} has fewer than {m['start']} lines.")
    return problems


def missing_claim_evidence(model: dict, root: pathlib.Path) -> list[str]:
    problems = []
    for i, c in enumerate(model.get("claims", [])):
        if not isinstance(c, dict) or c.get("status") not in ("differs", "partial"):
            continue
        raw = str(c.get("evidence", ""))
        if raw.startswith("base:"):
            continue  # code the PR deleted is not in the head checkout
        m = EVIDENCE.fullmatch(raw)
        target = root / m["path"] if m else None
        if not m or not target.is_file() or not 1 <= int(m["start"]) <= len(target.read_text(errors="replace").splitlines()):
            problems.append(f"claims[{i}].evidence: {c.get('evidence')!r} is not a file:line that exists under {root}.")
    return problems


NODE = re.compile(r"(\w+)(?:\[[^\]]*\]|\([^)]*\)|\{[^}]*\})?")
ARROW = re.compile(r"\s*(?:-->|==>|-\.->)(?:\|[^|]*\|)?\s*")


def mermaid_edges(section: str) -> set[tuple[str, str]]:
    """Edges of the first Mermaid fence. A chain `a --> b --> c` gives (a, b) and (b, c); `a & b --> c` gives
    (a, c) and (b, c); `==>` and `-.->` count as arrows."""
    blocks = re.findall(r"```mermaid\n(.*?)```", section, flags=re.S)
    if not blocks:
        return set()
    edges: set[tuple[str, str]] = set()
    for line in blocks[0].splitlines():
        parts = ARROW.split(line.strip())
        if len(parts) < 2:
            continue
        groups = [[m.group(1) for m in (NODE.match(p.strip()) for p in part.split("&")) if m] for part in parts]
        for left, right in zip(groups, groups[1:]):
            edges.update((a, b) for a in left for b in right)
    return edges


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", type=pathlib.Path)
    parser.add_argument("--section", type=pathlib.Path)
    parser.add_argument("--files", type=pathlib.Path)
    parser.add_argument("--root", type=pathlib.Path)
    parser.add_argument("--lang", choices=("ja", "en"))
    args = parser.parse_args()

    try:
        model = json.loads(args.model.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        print(f"{args.model}: cannot read the model ({exc}). Write pr-<n>.json first.", file=sys.stderr)
        return 2

    problems = check_model(model)
    if args.lang and not problems:
        problems.extend(language_problems(model, args.lang))

    if args.files and not problems:
        names = [n for n in args.files.read_text().splitlines() if n.strip()]
        problems.extend(coverage_problems(model, names))
        if model.get("mode") == "reviewer":
            for i, u in enumerate(model.get("unmentioned", [])):
                if not isinstance(u, dict):
                    continue
                path = str(u.get("path"))
                listed = {str(x.get("path")) for x in model.get("unmentioned", []) if isinstance(x, dict)}
                if path.endswith("/"):
                    under = [n for n in names if n.startswith(path) and n not in listed]
                    if not under:
                        problems.append(f"unmentioned[{i}].path: no changed file is under {path!r}.")
                    elif isinstance(u.get("count"), int) and u["count"] != len(under):
                        problems.append(f"unmentioned[{i}]: count is {u['count']} but {len(under)} changed files are under {path!r} that no other unmentioned entry lists.")
                elif path not in names:
                    problems.append(f"unmentioned[{i}].path: {path!r} is not a changed file of this PR.")
    if args.root and not problems and model["diagram"]["type"] != "none":
        problems.extend(missing_evidence(model, args.root))
    if args.root and not problems and model.get("mode") == "reviewer":
        problems.extend(missing_claim_evidence(model, args.root))

    if args.section and not problems:
        text = args.section.read_text()
        for m in VERDICT.finditer(text):
            problems.append(f"section contains the verdict word {m.group(0)!r}: this skill reads a diff and does not know runtime impact. Reword it as a fact or as the author's judgment.")
            break
        if len(text) > MAX_SECTION and model.get("mode") != "reviewer":
            problems.append(f"section is {len(text)} characters (limit {MAX_SECTION}; the PR body is capped at 65536 and the existing body counts). Group `reading_order` by directory.")
        elif len(text) > (WARN_REPORT if model.get("mode") == "reviewer" else WARN_SECTION):
            print(f"note: the {'report' if model.get('mode') == 'reviewer' else 'section'} is {len(text)} characters; the reader has to check all of it. Cut what does not change a decision.", file=sys.stderr)
    if args.section and not problems and model["diagram"]["type"] == "mermaid":
        drawn = mermaid_edges(args.section.read_text())
        wanted = {(e["from"], e["to"]) for e in model["diagram"]["edges"]}
        for edge in sorted(drawn - wanted):
            problems.append(f"edge {edge[0]} --> {edge[1]} is in the Mermaid source but not in the model: invented. Remove it or cite it.")
        for edge in sorted(wanted - drawn):
            problems.append(f"edge {edge[0]} --> {edge[1]} is in the model but not drawn: missing. Draw it or drop it.")

    for line in problems:
        print(line)
    if problems:
        return 1
    print("ok: model complete" + (" and edges agree both ways" if args.section else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
