#!/usr/bin/env python3
"""PostToolUse hook: remind Claude to run pr-map after a PR is created, and when a push made the map stale.

Usage (from settings.json, stdin is the hook's JSON): nudge.py create | push

  create  after `gh pr create`: tells Claude to ASK the user whether to run pr-map for the new PR, with a
          recommendation from the PR's size, whether a reviewer is requested and how often this repository's recent PRs got a
          human review (a small PR nobody else reviews is probably self-merged, and the map is not worth its tokens). A PUBLIC repository adds "privacy check and confirm
          first"; a draft may wait. PR_MAP_AUTO=always drops the question and says to run it.
  push    after `git push`: only when this branch's PR body already holds a map whose recorded commit differs from
          the current head. Says which cited files changed since. Silent for a PR with no map, and when the map is current.

A hook can add context for Claude but cannot run Claude, so this only reminds; the skill does the work.
It acts only when the command really runs `gh pr create` or `git push` (a heredoc body, an echo or a grep that merely
mentions the text does not count).
It never blocks and never fails the tool call: any problem means silence and exit 0.
PR_MAP_AUTO=0 turns it off; =always makes `create` say to run the skill without asking.
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


# Thresholds come from data, not a guess. October 2026, 761 merged PRs in the repositories the author was most active in
# (15 repositories, last 100 merged PRs each) and, for context, 10,209 merged PRs lab-wide (a BigQuery PR-facts view):
#   - PR size (files / changed lines): median 3 / 97, 75th percentile 8 / 319, 90th percentile 16 / 1,570.
#   - From about 6-8 files or 200-400 lines the share of PRs that got a human review rose from about 27% to 47-51%, the
#     share with changes requested from 3% to 10-19%, and the median lead time from 0.1 h to 0.5-3 h.
#   - Review is a property of the repository far more than of the PR: the share of merged PRs with a human review was
#     0% in every repository the author merges alone and 32-99% in the repositories with colleagues (lab-wide: 24%, and
#     size barely moved it there). So the repository's own history is the first signal, size the second.
# A GitHub review undercounts the reader of an agent-made PR in a repository merged alone: the author reads it before
# merging, which is the case the map was made for, so a large PR still earns a recommendation there.
LARGE_FILES, LARGE_LINES = 8, 300        # top quartile of the author's PRs: the bar when the author is the only reader
MEDIUM_FILES, MEDIUM_LINES = 6, 200      # where review effort starts to climb: the bar when colleagues review the repository
TINY_FILES, TINY_LINES = 2, 50           # at or below both, a map costs more than the diff
REVIEW_CULTURE = 0.25                    # a repository whose recent merged PRs got a human review at least this often
HISTORY = 30                             # recent merged PRs read to judge it


def review_history(owner: str, repo: str, cwd: str) -> tuple[int, int] | None:
    """(merged PRs read, how many had a human review by someone other than the author), or None when it cannot be read."""
    raw = gh("pr", "list", "-R", f"{owner}/{repo}", "--state", "merged", "--limit", str(HISTORY), "--json", "author,reviews", cwd=cwd)
    try:
        prs = json.loads(raw or "")
    except ValueError:
        return None
    if not isinstance(prs, list) or not prs:
        return None

    def human(login: str | None, author: str | None) -> bool:
        return bool(login) and login != author and not login.endswith("[bot]") and login not in ("github-actions", "dependabot", "Copilot", "copilot-pull-request-reviewer")

    reviewed = 0
    for pr in prs:
        author = (pr.get("author") or {}).get("login")
        if any(human((rv.get("author") or {}).get("login"), author) for rv in pr.get("reviews") or []):
            reviewed += 1
    return len(prs), reviewed


def size_advice(owner: str, repo: str, number: str, cwd: str) -> str:
    """One sentence: the PR's size, the repository's review habit, and whether a reviewer's map is likely worth its cost."""
    raw = gh("pr", "view", number, "-R", f"{owner}/{repo}", "--json", "changedFiles,additions,deletions,reviewRequests", cwd=cwd)
    try:
        d = json.loads(raw or "")
        files, lines, reviewers = int(d["changedFiles"]), int(d["additions"]) + int(d["deletions"]), len(d.get("reviewRequests") or [])
    except (ValueError, KeyError, TypeError):
        return "Its size could not be read; recommend asking without a default."
    size = f"It changes {files} file(s) and {lines} line(s)"
    if reviewers:
        return f"{size} and a reviewer is requested: recommend running it."
    if files <= TINY_FILES and lines < TINY_LINES:
        return f"{size}, which is tiny: recommend skipping it."
    history = review_history(owner, repo, cwd)
    if history and history[0] >= 10 and history[1] / history[0] >= REVIEW_CULTURE:
        n, reviewed = history
        if files >= MEDIUM_FILES or lines >= MEDIUM_LINES:
            return (f"{size}, and {reviewed} of the last {n} merged PRs in this repository had a human review, so a colleague probably "
                    "reads it: recommend running it.")
        return f"{size}, below the bar even though {reviewed} of the last {n} merged PRs here had a human review: recommend skipping it."
    seen = f" ({history[1]} of the last {history[0]} merged PRs here had a human review)" if history else ""
    if files >= LARGE_FILES or lines >= LARGE_LINES:
        return (f"{size}, which is large{seen}: the author is probably its only reader, but a large agent-made PR is hard to "
                "review alone: recommend running it.")
    return f"{size}{seen}, and nobody else is likely to review it: recommend skipping it."


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
        parts = [f"PR #{number} was created ({url}). The user's setting is to always run the pr-map skill (author mode) for it and make its output the PR body.", privacy]
    else:
        parts = [f"PR #{number} was created ({url}). Do not run the pr-map skill on your own: ask the user whether to run it for this PR "
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
    emit(f"PR #{data['number']}'s map was made at {result['recorded'][:10]}; the branch is now at {result['current'][:10]} "
         f"({len(result['changed'])} file(s) changed).{detail} The map is stale: re-run pr-map when the PR is ready for review, "
         "or now if the user asks. Re-running replaces only the block between its markers.")


def main() -> int:
    try:
        mode = os.environ.get("PR_MAP_AUTO", os.environ.get("PR_EXPLAINER_AUTO", "ask"))  # the old name still works
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
