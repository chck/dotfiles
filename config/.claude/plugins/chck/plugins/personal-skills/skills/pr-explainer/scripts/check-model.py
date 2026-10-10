#!/usr/bin/env python3
"""Check that the pr-explainer model is complete before any prose is written.

Usage: check-model.py <pr-N.json> [--section section.md] [--files names.txt] [--root DIR]

Fails on a missing key, an empty entry, or a placeholder ("...", TODO, TBD). With --section it
also compares the edges of the Mermaid fence in the section with `diagram.edges`, in both
directions; `from` and `to` in the model are the Mermaid node ids. A section with a verdict word
(SAFE, LOW RISK, MERGEABLE, "no impact", 影響なし) fails, and so does one over 40000 characters (the
whole PR body is limited to 65536, and the existing body counts too).
--files takes the output of `gh pr diff <n> --name-only`: every file must be covered by a `changes`
entry, either its exact path or a directory entry ending in `/`. --root checks that each
`diagram.edges[].evidence` (`path:line`) names a line that exists.

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
MAX_SECTION = 40000
WARN_SECTION = 15000
EVIDENCE = re.compile(r"(?P<path>.+?):(?P<start>\d+)(?:-(?P<end>\d+))?")
DIAGRAM_TYPES = {"mermaid", "sequence", "data-flow", "architecture", "none"}

# key -> (kind, required fields per entry)
LISTS = {
    "review_order": ("list", ("path", "why")),
    "changes": ("list", ("path", "what")),
    "evidence": ("list", ("claim", "cmd", "output")),
    "unverified": ("list", ("claim", "why_not")),
    "risks": ("list", ("where", "what", "how_to_check")),
}


def blank(value: object) -> bool:
    return not isinstance(value, str) or bool(PLACEHOLDER.match(value))


def check_model(model: dict) -> list[str]:
    problems: list[str] = []
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
    if not model.get("review_order"):
        problems.append("review_order: empty. A PR with files has an order to read them in.")
    concepts = model.get("new_concepts")
    if not isinstance(concepts, list) or any(blank(c) for c in concepts):
        problems.append("new_concepts: must be a list of non-empty strings (empty list is fine).")
    cov = model.get("coverage")
    if not (isinstance(cov, dict) and isinstance(cov.get("files_total"), int) and isinstance(cov.get("files_opened"), int)):
        problems.append("coverage: needs integer files_total and files_opened, so the body can say how much was read.")
    elif cov["files_opened"] > cov["files_total"]:
        problems.append("coverage: files_opened is larger than files_total.")
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


def uncovered(model: dict, files: list[str]) -> list[str]:
    paths = [c.get("path", "") for c in model.get("changes", []) if isinstance(c, dict)]
    return [f for f in files if not any(f == p or (p.endswith("/") and f.startswith(p)) for p in paths)]


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


def mermaid_edges(section: str) -> set[tuple[str, str]]:
    blocks = re.findall(r"```mermaid\n(.*?)```", section, flags=re.S)
    if not blocks:
        return set()
    edges: set[tuple[str, str]] = set()
    for line in blocks[0].splitlines():
        for src, dst in re.findall(r"(\w+)(?:\[[^\]]*\]|\([^)]*\)|\{[^}]*\})?\s*-->(?:\|[^|]*\|)?\s*(\w+)", line):
            edges.add((src, dst))
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
        missing = uncovered(model, names)
        for name in missing[:10]:
            problems.append(f"{name}: no `changes` entry covers this file. Add one, or a directory entry ending in `/`.")
        if len(missing) > 10:
            problems.append(f"... and {len(missing) - 10} more files without a `changes` entry.")
    if args.root and not problems and model["diagram"]["type"] != "none":
        problems.extend(missing_evidence(model, args.root))

    if args.section and not problems:
        text = args.section.read_text()
        for m in VERDICT.finditer(text):
            problems.append(f"section contains the verdict word {m.group(0)!r}: this skill reads a diff and does not know runtime impact. Reword it as a fact or as the author's judgment.")
            break
        if len(text) > MAX_SECTION:
            problems.append(f"section is {len(text)} characters (limit {MAX_SECTION}; the PR body is capped at 65536 and the existing body counts). Group `changes` by directory.")
        elif len(text) > WARN_SECTION:
            print(f"note: section is {len(text)} characters; consider grouping `changes` by area.", file=sys.stderr)
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
