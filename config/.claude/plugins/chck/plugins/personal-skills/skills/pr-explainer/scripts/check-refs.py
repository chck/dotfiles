#!/usr/bin/env python3
"""Check that every file path cited in a PR body section exists in the checkout.

Usage: check-refs.py <body.md> [--expect-head <sha>] [--root <dir>]

Scans backticked spans for `path` and `path:line` / `path:start-end` and fails when
a path is not tracked at HEAD or a line number is past the end of the file. Spans
without a file extension (and not ending in `/`) are not paths and are ignored,
so `origin/main` and `pr-assets` pass through.

--expect-head fails fast when HEAD is not the PR head commit, so a stale checkout
cannot vouch for the wrong tree.

Exit 0: all cited paths verified. Exit 1: at least one problem. Exit 2: usage or git error.
"""

from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys

SPAN = re.compile(r"`([^`\n]+)`")
PATH = re.compile(r"(?P<path>[\w.@+-]+(?:/[\w.@+-]+)*(?:\.\w{1,8}|/))(?::(?P<start>\d+)(?:-(?P<end>\d+))?)?")


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
    checked = 0

    for span in dict.fromkeys(SPAN.findall(args.body.read_text())):
        match = PATH.fullmatch(span)
        if not match:
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
        for bound in (match["start"], match["end"]):
            if bound is None:
                continue
            length = len((args.root / path).read_text(errors="replace").splitlines())
            if int(bound) > length or int(bound) < 1:
                problems.append(f"`{span}`: {path} has {length} lines. Fix the line number.")
                break

    for line in problems:
        print(line)
    if problems:
        return 1
    print(f"ok: {checked} cited path(s) verified at {head[:10]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
