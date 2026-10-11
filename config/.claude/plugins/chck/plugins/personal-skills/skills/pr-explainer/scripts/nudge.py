#!/usr/bin/env python3
"""PostToolUse hook: remind Claude to run pr-explainer after a PR is created, and when a push made the map stale.

Usage (from settings.json, stdin is the hook's JSON): nudge.py create | push

  create  after `gh pr create`: "PR #N exists: run pr-explainer (author mode) and write the result as its body".
          A PUBLIC repository gets "run the privacy check and ask the user first"; a draft gets "may wait until ready".
  push    after `git push`: only when this branch's PR body already holds a map whose recorded commit differs from
          the current head. Says which cited files changed since. Silent for a PR with no map, and when the map is current.

A hook can add context for Claude but cannot run Claude, so this only reminds; the skill does the work.
It never blocks and never fails the tool call: any problem means silence and exit 0.
PR_EXPLAINER_AUTO=0 turns it off.
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


def on_create(command: str, output: str, cwd: str) -> None:
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
    parts = [f"PR #{number} was created ({url}). The user's workflow: run the pr-explainer skill (author mode) for it and make its output the PR body; do not hand-write the body."]
    if visibility == "PUBLIC":
        parts.append("The repository is PUBLIC: run the skill's privacy check and ask the user before writing the body or pushing an image.")
    elif visibility == "PRIVATE":
        parts.append("The repository is private: run it now.")
    else:
        parts.append("Could not read the repository's visibility: treat it as public and ask the user before writing the body.")
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
        if os.environ.get("PR_EXPLAINER_AUTO") == "0" or len(sys.argv) < 2:
            return 0
        data = json.load(sys.stdin)
        command = str((data.get("tool_input") or {}).get("command", ""))
        cwd = str(data.get("cwd") or ".")
        if sys.argv[1] == "create" and "gh pr create" in command:
            on_create(command, flatten(data.get("tool_response")) + "\n" + flatten(data.get("tool_output")), cwd)
        elif sys.argv[1] == "push" and "git push" in command:
            on_push(cwd)
    except Exception:  # a reminder must never break the tool call it follows
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
