#!/usr/bin/env python3
"""Check that every file path cited in a PR body section exists in the checkout.

Usage: check-refs.py <body.md> [--expect-head <sha>] [--root <dir>]

Scans backticked spans for `path` and `path:line` / `path:start-end` and fails when
a path is not tracked at HEAD or a line number is past the end of the file. Spans
without a file extension (and not ending in `/`) are not paths and are ignored,
so `origin/main` and `pr-assets` pass through. A span with no `/` counts as a file
only for a common source/doc extension, so `ast.parse` passes through too.

--expect-head fails fast when HEAD is not the PR head commit, so a stale checkout
cannot vouch for the wrong tree.

Routes such as `/privacy` (leading slash) and globs such as `src/*.ts` are not checked: cite a
directory ending in `/` instead of a glob, and write deleted files in plain text, since a deleted
file is not tracked at HEAD.

For every cited `path:line` the script prints the text of that line. It only checks that the
line exists, so read each printed line and confirm it says what the body claims.

Fenced code blocks are skipped (pasted output is not a citation), as link-refs.py does.

Spans that look like a bare file name but have an unrecognised extension are listed on stderr as
not checked, so a missing extension in _refs.py is visible instead of silent.

Exit 0: all cited paths verified. Exit 1: at least one problem. Exit 2: usage or git error.
"""

from __future__ import annotations

import argparse
import pathlib
import subprocess
import sys

from _refs import PATH, SPAN, fenced_lines, parse_span


def unfenced(text: str) -> str:
    """The text outside fenced code blocks: pasted output is not a citation (link-refs.py skips it too)."""
    return "\n".join(line for line, fenced in fenced_lines(text) if not fenced)


def git(root: pathlib.Path, *args: str) -> str:
    result = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"git {' '.join(args)} failed in {root}: {result.stderr.strip()}", file=sys.stderr)
        sys.exit(2)
    return result.stdout


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("body", type=pathlib.Path)
    parser.add_argument("--expect-head")
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path("."))
    args = parser.parse_args()

    if not args.body.is_file():
        print(f"{args.body}: no such file. Pass the PR body section you wrote.", file=sys.stderr)
        return 2

    head = git(args.root, "rev-parse", "HEAD").strip()
    if args.expect_head and head != args.expect_head:
        print(
            f"HEAD is {head[:10]} but the PR head is {args.expect_head[:10]}. "
            "Run from the PR's checkout (git fetch, then check out the PR branch).",
            file=sys.stderr,
        )
        return 2

    tracked = set(git(args.root, "ls-files").splitlines())
    problems: list[str] = []
    cited_lines: list[str] = []
    skipped: list[str] = []
    checked = 0

    for span in dict.fromkeys(SPAN.findall(unfenced(args.body.read_text()))):
        if span.endswith(":") and parse_span(span[:-1]):
            problems.append(f"`{span}`: ends with a colon and no line number. Add the line (path:line) or drop the colon.")
            continue
        match = parse_span(span)
        if not match:
            if PATH.fullmatch(span) and "/" not in span:
                skipped.append(f"`{span}`")
            continue
        path = match["path"]
        checked += 1
        if path.endswith("/"):
            if not any(f.startswith(path) for f in tracked):
                problems.append(f"`{span}`: no tracked file under {path}. Fix the directory name or drop the claim.")
            continue
        if path not in tracked:
            same_name = sorted(f for f in tracked if f.rsplit("/", 1)[-1] == path)
            hint = f" Use the repo-relative path: {', '.join(same_name[:3])}." if same_name else ""
            problems.append(f"`{span}`: {path} is not tracked at HEAD.{hint} Otherwise fix the path or drop the claim.")
            continue
        file_lines = (args.root / path).read_text(errors="replace").splitlines()
        for bound in (match["start"], match["end"]):
            if bound is None:
                continue
            if int(bound) > len(file_lines) or int(bound) < 1:
                problems.append(f"`{span}`: {path} has {len(file_lines)} lines. Fix the line number.")
                break
            cited_lines.append(f"  {path}:{bound}: {file_lines[int(bound) - 1].strip()[:100]}")

    for line in dict.fromkeys(cited_lines):
        print(line)
    for line in problems:
        print(line)
    if skipped:
        print(f"note (not a failure): not checked as files, no slash and an unrecognised extension: {', '.join(skipped[:5])}", file=sys.stderr)
    if problems:
        return 1
    shown = len(dict.fromkeys(cited_lines))
    print(f"ok: {checked} cited path(s) verified at {head[:10]}")
    if shown:
        print(f"Not done by this script: read the {shown} cited line(s) above and confirm each says what the body claims.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
