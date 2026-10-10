#!/usr/bin/env python3
"""Check that the pr-explainer model is complete before any prose is written.

Usage: check-model.py <pr-N.json> [--section section.md] [--files names.txt] [--root DIR]

The model's optional "mode" is "author" (default) or "reviewer". A reviewer model also needs `claims`,
`unmentioned`, `test_gaps` and `questions`; with --files every `unmentioned` path must be a changed file. A
reviewer report is not a PR body, so the size limit only prints a note.

Fails on a missing key, an empty entry, or a placeholder ("...", TODO, TBD). With --section it
also compares the edges of the Mermaid fence in the section with `diagram.edges`, in both
directions; `from` and `to` in the model are the Mermaid node ids. Run it on the section after the
citations are linked: links add 40-60% to the length. A section with a verdict word
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
MAX_WHAT = 300
MODES = ("author", "reviewer")
STATUS = ("matches", "differs", "not_in_diff", "not_checked")
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
        "test_gaps": ("behaviour", "where", "note"),
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
            if key == "claims" and isinstance(entry, dict) and entry.get("status") not in STATUS:
                problems.append(f"claims[{i}].status: {entry.get('status')!r} is not one of {', '.join(STATUS)}.")
    return problems


def check_model(model: dict) -> list[str]:
    problems: list[str] = []
    mode = model.get("mode", "author")
    if mode not in MODES:
        problems.append(f"mode: {mode!r} is not one of {', '.join(MODES)}.")
    elif mode == "reviewer":
        problems.extend(reviewer_problems(model))
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


NODE = re.compile(r"(\w+)(?:\[[^\]]*\]|\([^)]*\)|\{[^}]*\})?")


def mermaid_edges(section: str) -> set[tuple[str, str]]:
    """Edges of the first Mermaid fence; a chain `a --> b --> c` gives (a, b) and (b, c)."""
    blocks = re.findall(r"```mermaid\n(.*?)```", section, flags=re.S)
    if not blocks:
        return set()
    edges: set[tuple[str, str]] = set()
    for line in blocks[0].splitlines():
        parts = re.split(r"\s*-->(?:\|[^|]*\|)?\s*", line.strip())
        if len(parts) < 2:
            continue
        ids = [m.group(1) for m in (NODE.match(p) for p in parts) if m]
        edges.update(zip(ids, ids[1:]))
    return edges


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("model", type=pathlib.Path)
    parser.add_argument("--section", type=pathlib.Path)
    parser.add_argument("--files", type=pathlib.Path)
    parser.add_argument("--root", type=pathlib.Path)
    args = parser.parse_args()

    try:
        model = json.loads(args.model.read_text())
    except (OSError, json.JSONDecodeError) as exc:
        print(f"{args.model}: cannot read the model ({exc}). Write pr-<n>.json first.", file=sys.stderr)
        return 2

    problems = check_model(model)

    if args.files and not problems:
        names = [n for n in args.files.read_text().splitlines() if n.strip()]
        problems.extend(coverage_problems(model, names))
        if model.get("mode") == "reviewer":
            for i, u in enumerate(model.get("unmentioned", [])):
                if isinstance(u, dict) and u.get("path") not in names:
                    problems.append(f"unmentioned[{i}].path: {u.get('path')!r} is not a changed file of this PR.")
    if args.root and not problems and model["diagram"]["type"] != "none":
        problems.extend(missing_evidence(model, args.root))

    if args.section and not problems:
        text = args.section.read_text()
        for m in VERDICT.finditer(text):
            problems.append(f"section contains the verdict word {m.group(0)!r}: this skill reads a diff and does not know runtime impact. Reword it as a fact or as the author's judgment.")
            break
        if len(text) > MAX_SECTION and model.get("mode") != "reviewer":
            problems.append(f"section is {len(text)} characters (limit {MAX_SECTION}; the PR body is capped at 65536 and the existing body counts). Group `reading_order` by directory.")
        elif len(text) > WARN_SECTION:
            print(f"note: section is {len(text)} characters; consider grouping `reading_order` by area.", file=sys.stderr)
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
