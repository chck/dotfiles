#!/usr/bin/env python3
"""Say whether a pr-explainer map or report has gone stale because the PR moved on.

Usage: stale-check.py <file.md> [--root DIR] [--head SHA]
       stale-check.py --pr N [--repo OWNER/REPO] [--root DIR] [--head SHA]

Reads the commit the text was made at (the head comment of a map, or the "Target commit" line of a reviewer report),
compares it with the current head of --root (default "."), and lists the changed files and which of the paths the text
cites are among them. A cited path that changed is where a ★ line, a question or a gap may already be answered.

Exit 0: current. Exit 1: stale. Exit 2: unknown (no recorded commit, the old commit is not in this clone, or an error).
"""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys

from _stale import check


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", nargs="?", type=pathlib.Path)
    parser.add_argument("--pr", type=int)
    parser.add_argument("--repo")
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path("."))
    parser.add_argument("--head")
    args = parser.parse_args()

    if args.pr:
        cmd = ["gh", "pr", "view", str(args.pr), "--json", "body", "-q", ".body"] + (["-R", args.repo] if args.repo else [])
        r = subprocess.run(cmd, capture_output=True, text=True)
        if r.returncode != 0:
            print(f"could not read the body of PR {args.pr}: {r.stderr.strip()}. Check gh auth and the repository.", file=sys.stderr)
            return 2
        text = r.stdout
    elif args.file and args.file.is_file():
        text = args.file.read_text()
    else:
        print("pass a Markdown file or --pr N.", file=sys.stderr)
        return 2

    result = check(text, args.root, args.head)
    if result["status"] == "unknown":
        why = "records no commit" if not result["recorded"] else f"was made at {result['recorded'][:10]}, which is not in this clone (fetch it)"
        print(f"unknown: the text {why}.")
        return 2
    if result["status"] == "current":
        print(f"current: made at {result['recorded'][:10]}, the head is {result['current'][:10]}.")
        return 0
    print(f"stale: made at {result['recorded'][:10]}, the head is now {result['current'][:10]}; {len(result['changed'])} file(s) changed since.")
    for p in result["cited_changed"]:
        print(f"  cited and changed: {p}")
    if not result["cited_changed"]:
        print("  none of the cited paths changed (the map may still describe the right files).")
    return 1


if __name__ == "__main__":
    sys.exit(main())
