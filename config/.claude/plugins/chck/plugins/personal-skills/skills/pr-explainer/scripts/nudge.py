#!/usr/bin/env python3
"""PostToolUse hook: remind Claude to run pr-explainer after a PR is created, and when a push made the map stale.

Usage (from settings.json, stdin is the hook's JSON): nudge.py create | push

  create  after `gh pr create`: tells Claude to ASK the user whether to run pr-explainer for the new PR, with a
          recommendation from the PR's size and whether a reviewer is requested (a small PR nobody else reviews is
          probably self-merged, and the map is not worth its tokens). A PUBLIC repository adds "privacy check and confirm
          first"; a draft may wait. PR_EXPLAINER_AUTO=always drops the question and says to run it.
  push    after `git push`: only when this branch's PR body already holds a map whose recorded commit differs from
          the current head. Says which cited files changed since. Silent for a PR with no map, and when the map is current.

A hook can add context for Claude but cannot run Claude, so this only reminds; the skill does the work.
It acts only when the command really runs `gh pr create` or `git push` (a heredoc body, an echo or a grep that merely
mentions the text does not count).
It never blocks and never fails the tool call: any problem means silence and exit 0.
PR_EXPLAINER_AUTO=0 turns it off; =always makes `create` say to run the skill without asking.
"""

from __future__ import annotations

import json
import os
import pathlib
import re
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

from _stale import check  # noqa: E402

HEREDOC = re.compile(r"<<-?\s*['\"]?(\w+)['\"]?[^\n]*\n.*?\n\s*\1\b", re.S)
CREATE = r"gh\s+pr\s+create"
PUSH = r"git\s+(?:-[Cc]\s+\S+\s+)*push"


def runs(command: str, what: str) -> bool:
    """True when `what` is run at a command position (the start, or after ; & | ( or a newline, or after VAR=value),
    not merely mentioned in text: heredoc bodies, echo and grep arguments, comments."""
    body = HEREDOC.sub("", command)
    return re.search(r"(?:^|[;&|(\n])\s*(?:\w+=\S*\s+)*" + what + r"(?:\s|$|\))", body) is not None


PR_URL = re.compile(r"https://github\.com/([^/\s]+)/([^/\s]+)/pull/(\d+)")


def flatten(value: object) -> str:
    if isinstance(value, str):
        return value
    if isinstance(value, dict):
        return "\n".join(flatten(v) for v in value.values())
    if isinstance(value, list):
        return "\n".join(flatten(v) for v in value)
    return ""


def gh(*args: str, cwd: str) -> str | None:
    try:
        r = subprocess.run(["gh", *args], capture_output=True, text=True, timeout=15, cwd=cwd)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return r.stdout if r.returncode == 0 else None


def emit(message: str) -> None:
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": message}}, ensure_ascii=False))


LARGE_FILES = 8
LARGE_LINES = 300


def size_advice(owner: str, repo: str, number: str, cwd: str) -> str:
    """One sentence: how big the PR is and whether a reviewer's map is likely worth its cost."""
    raw = gh("pr", "view", number, "-R", f"{owner}/{repo}", "--json", "changedFiles,additions,deletions,reviewRequests", cwd=cwd)
    try:
        d = json.loads(raw or "")
        files, lines, reviewers = int(d["changedFiles"]), int(d["additions"]) + int(d["deletions"]), len(d.get("reviewRequests") or [])
    except (ValueError, KeyError, TypeError):
        return "Its size could not be read; recommend asking without a default."
    size = f"It changes {files} file(s) and {lines} line(s)"
    if reviewers:
        return f"{size} and a reviewer is requested: recommend running it."
    if files >= LARGE_FILES or lines >= LARGE_LINES:
        return f"{size}, which is large: recommend running it."
    return f"{size} and no reviewer is requested, so it is probably merged by its author: recommend skipping it."


def on_create(command: str, output: str, cwd: str, mode: str) -> None:
    m = PR_URL.search(output)
    if m:
        owner, repo, number = m[1], m[2], m[3]
        url = m[0]
    else:
        info = gh("pr", "view", "--json", "url,number", "-q", '.url + " " + (.number|tostring)', cwd=cwd)
        if not info or not (m := PR_URL.search(info)):
            return
        owner, repo, number, url = m[1], m[2], m[3], m[0]
    visibility = (gh("repo", "view", f"{owner}/{repo}", "--json", "visibility", "-q", ".visibility", cwd=cwd) or "").strip()
    draft = bool(re.search(r"(^|\s)(--draft|-d)(\s|$)", command))
    if visibility == "PUBLIC":
        privacy = "The repository is PUBLIC: run the skill's privacy check and confirm with the user before writing the body or pushing an image."
    elif visibility == "PRIVATE":
        privacy = "The repository is private."
    else:
        privacy = "Could not read the repository's visibility: treat it as public (privacy check, confirm before writing)."
    if mode == "always":
        parts = [f"PR #{number} was created ({url}). The user's setting is to always run the pr-explainer skill (author mode) for it and make its output the PR body.", privacy]
    else:
        parts = [f"PR #{number} was created ({url}). Do not run the pr-explainer skill on your own: ask the user whether to run it for this PR "
                 "(AskUserQuestion, options: run it, skip), because a PR that only its author merges rarely needs a reviewer's map and the run costs tokens.",
                 size_advice(owner, repo, number, cwd), privacy,
                 "If the user skips, leave the body as a short plain summary of the change."]
    if draft:
        parts.append("It is a draft: the map may wait until the PR is marked ready for review.")
    emit(" ".join(parts))


def on_push(cwd: str) -> None:
    info = gh("pr", "view", "--json", "number,url,body", cwd=cwd)
    if not info:
        return
    data = json.loads(info)
    body = data.get("body") or ""
    if "<!-- pr-explainer:start -->" not in body:
        return
    result = check(body, pathlib.Path(cwd))
    if result["status"] != "stale":
        return
    cited = result["cited_changed"]
    detail = (f" Files it cites that changed since: {', '.join(cited[:8])}{' ...' if len(cited) > 8 else ''}." if cited
              else " None of the files it cites changed.")
    emit(f"PR #{data['number']}'s pr-explainer map was made at {result['recorded'][:10]}; the branch is now at {result['current'][:10]} "
         f"({len(result['changed'])} file(s) changed).{detail} The map is stale: re-run pr-explainer when the PR is ready for review, "
         "or now if the user asks. Re-running replaces only the block between its markers.")


def main() -> int:
    try:
        mode = os.environ.get("PR_EXPLAINER_AUTO", "ask")
        if mode == "0" or len(sys.argv) < 2:
            return 0
        data = json.load(sys.stdin)
        command = str((data.get("tool_input") or {}).get("command", ""))
        cwd = str(data.get("cwd") or ".")
        if sys.argv[1] == "create" and runs(command, CREATE):
            on_create(command, flatten(data.get("tool_response")) + "\n" + flatten(data.get("tool_output")), cwd, mode)
        elif sys.argv[1] == "push" and runs(command, PUSH):
            on_push(cwd)
    except Exception:  # a reminder must never break the tool call it follows
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
