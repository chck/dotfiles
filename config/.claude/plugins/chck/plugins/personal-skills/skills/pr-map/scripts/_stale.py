"""Shared by stale-check.py and nudge.py: has the PR moved since a map or a report was made?

A map (author mode) records its commit in a comment inside the block, `<!-- pr-explainer:head <sha> -->`.
A reviewer report names it on the Mode line ("Target commit: <sha>" / "対象 commit: <sha>").
"""

from __future__ import annotations

import pathlib
import re
import subprocess

from _refs import SPAN, fenced_lines, parse_span

HEAD_COMMENT = re.compile(r"<!--\s*pr-explainer:head\s+([0-9a-f]{7,40})\s*-->")
REPORT_HEAD = re.compile(r"(?:対象 commit|Target commit)\s*[:：]\s*`?([0-9a-f]{7,40})`?")


def recorded_head(text: str) -> str | None:
    """The commit a map or a report was made at, or None when the text records none."""
    for pattern in (HEAD_COMMENT, REPORT_HEAD):
        m = pattern.search(text)
        if m:
            return m[1]
    return None


def cited_paths(text: str) -> set[str]:
    """Repo paths (and directories ending in /) cited in backticks outside fenced code."""
    prose = "\n".join(line for line, fenced in fenced_lines(text) if not fenced)
    found = set()
    for span in SPAN.findall(prose):
        m = parse_span(span)
        if m:
            found.add(m["path"])
    return found


def git(root: pathlib.Path, *args: str, timeout: int = 15) -> str | None:
    try:
        r = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout if r.returncode == 0 else None


def check(text: str, root: pathlib.Path, head: str | None = None) -> dict:
    """status is current, stale or unknown (nothing recorded, or the old commit is not available locally)."""
    old = recorded_head(text)
    new = head or (git(root, "rev-parse", "HEAD") or "").strip()
    result: dict = {"recorded": old, "current": new, "changed": [], "cited_changed": [], "status": "unknown"}
    if not old or not new:
        return result
    if new.startswith(old) or old.startswith(new):
        result["status"] = "current"
        return result
    out = git(root, "diff", "--name-only", old, new)
    if out is None:
        return result  # the old commit is not in this clone: say so instead of guessing
    changed = [line for line in out.splitlines() if line]
    cited = cited_paths(text)
    result["changed"] = changed
    result["cited_changed"] = sorted(p for p in cited if any(c == p or (p.endswith("/") and c.startswith(p)) for c in changed))
    result["status"] = "stale"
    return result
