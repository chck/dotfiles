#!/usr/bin/env python3
"""Turn backticked file citations in a PR body section into links a reviewer can click and comment on.

Usage: link-refs.py <section.md> --repo OWNER/REPO --pr N --base-sha SHA --head-sha SHA
                    [--root DIR] [--blob-only] [--wrap-bare] [--write]

`path` and `path:line` / `path:a-b` become [`path:line`](url):
  - a file the PR changes, with every cited line inside a diff hunk (3 lines of context included):
    the PR's Files changed view, https://github.com/OWNER/REPO/pull/N/changes#diff-<sha256 of path>R<line>
    where a reviewer can comment on the line;
  - anything else that exists at the head commit: a permalink pinned to the head SHA,
    https://github.com/OWNER/REPO/blob/<head sha>/<path>#L<line>;
  - a directory ending in `/`: a tree link at the head SHA.
--wrap-bare first puts bare repo paths (a path with a slash that exists at the head commit, with an optional :line)
and identifiers with underscores in backticks, outside code, existing backticks, links and URLs: a reader's text has
them bare, and outside backticks Markdown reads the underscores as emphasis.
Citations that are not files at the head commit (deleted files, typos) are left as they are; run
check-refs.py first and fix those. Fenced code blocks and spans that are already links are not touched.
Reads git objects from --root (default "."), so a fetched PR head is enough; no checkout is needed.
Prints the linked text on stdout (or rewrites the file with --write) and a count of links on stderr.
"""

from __future__ import annotations

import argparse
import hashlib
import pathlib
import re
import subprocess
import sys
from urllib.parse import quote

from _refs import SPAN, parse_span

HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


def git(root: pathlib.Path, *args: str) -> str:
    result = subprocess.run(["git", "-C", str(root), "-c", "core.quotePath=false", *args], capture_output=True, text=True)
    if result.returncode != 0:
        print(f"git {' '.join(args)} failed in {root}: {result.stderr.strip()}. Fetch the PR head and base first.", file=sys.stderr)
        sys.exit(2)
    return result.stdout


def right_side_hunks(root: pathlib.Path, base: str, head: str) -> dict[str, list[tuple[int, int]]]:
    """Line ranges on the new side of each changed file, as the Files changed view shows them."""
    hunks: dict[str, list[tuple[int, int]]] = {}
    path: str | None = None
    for line in git(root, "diff", "-U3", "--no-color", "--no-renames", base, head).splitlines():
        if line.startswith("+++ "):
            path = None if line == "+++ /dev/null" else line[6:]
            if path is not None:
                hunks.setdefault(path, [])
        elif path is not None and (m := HUNK.match(line)):
            start, count = int(m[1]), int(m[2]) if m[2] is not None else 1
            if count:
                hunks[path].append((start, start + count - 1))
    return hunks


def line_suffix(prefix: str, start: str | None, end: str | None) -> str:
    if not start:
        return ""
    return f"#{prefix}{start}" if not end else f"#{prefix}{start}-{prefix}{end}"


PROTECTED = re.compile(r"`[^`\n]+`|\[[^\]]*\]\([^)]*\)|https?://\S+")
BARE_PATH = re.compile(r"(?<![\w/.@-])((?:[\w.@+()\[\]~-]+/)+[\w.@+()\[\]~-]+\.[A-Za-z0-9]{1,8})(:\d+(?:-\d+)?)?(?![\w/])")
IDENT = re.compile(r"(?<![\w`])([A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)+)(?![\w`])")


def wrap_bare(line: str, tree: set[str]) -> str:
    """Backtick bare repo paths and underscore identifiers in the parts of a line that are plain text."""
    def plain(text: str) -> str:
        text = BARE_PATH.sub(lambda m: f"`{m[0]}`" if m[1] in tree else m[0], text)
        return IDENT.sub(lambda m: f"`{m[1]}`", text)
    out, pos = [], 0
    for m in PROTECTED.finditer(line):
        out.append(plain(line[pos:m.start()]))
        out.append(m[0])
        pos = m.end()
    out.append(plain(line[pos:]))
    return "".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("section", type=pathlib.Path)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--pr", required=True, type=int)
    parser.add_argument("--base-sha", required=True)
    parser.add_argument("--head-sha", required=True)
    parser.add_argument("--root", type=pathlib.Path, default=pathlib.Path("."))
    parser.add_argument("--blob-only", action="store_true", help="always link the pinned file, never Files changed")
    parser.add_argument("--wrap-bare", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    if not args.section.is_file():
        print(f"{args.section}: no such file. Pass the section you wrote.", file=sys.stderr)
        return 2

    tree = set(git(args.root, "ls-tree", "-r", "--name-only", args.head_sha).splitlines())
    hunks = {} if args.blob_only else right_side_hunks(args.root, args.base_sha, args.head_sha)
    counts = {"files-changed": 0, "blob": 0, "tree": 0, "left plain": 0}

    def link(match: re.Match[str]) -> str:
        span = match[1]
        parsed = parse_span(span)
        if parsed is None:
            return match[0]
        path, start, end = parsed["path"], parsed["start"], parsed["end"]
        if path.endswith("/"):
            if not any(f.startswith(path) for f in tree):
                counts["left plain"] += 1
                return match[0]
            counts["tree"] += 1
            return f"[`{span}`](https://github.com/{args.repo}/tree/{args.head_sha}/{quote(path.rstrip('/'), safe='/')})"
        if path not in tree:
            counts["left plain"] += 1
            return match[0]
        cited = [int(n) for n in (start, end) if n]
        if path in hunks and all(any(a <= n <= b for a, b in hunks[path]) for n in cited):
            digest = hashlib.sha256(path.encode()).hexdigest()
            counts["files-changed"] += 1
            url = f"https://github.com/{args.repo}/pull/{args.pr}/changes#diff-{digest}"
            url += (f"R{start}" if not end else f"R{start}-R{end}") if start else ""
            return f"[`{span}`]({url})"
        counts["blob"] += 1
        return f"[`{span}`](https://github.com/{args.repo}/blob/{args.head_sha}/{quote(path, safe='/')}{line_suffix('L', start, end)})"

    out: list[str] = []
    fenced = False
    for line in args.section.read_text().splitlines():
        if line.lstrip().startswith("```"):
            fenced = not fenced
            out.append(line)
        elif fenced:
            out.append(line)
        else:
            if args.wrap_bare:
                line = wrap_bare(line, tree)
            out.append(re.sub(r"(?<!\[)`([^`\n]+)`(?!\]\()", link, line))
    text = "\n".join(out) + "\n"

    if args.write:
        args.section.write_text(text)
    else:
        sys.stdout.write(text)
    print("links: " + ", ".join(f"{k} {v}" for k, v in counts.items()), file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
