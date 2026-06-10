---
name: review-pr-comments
description: >
  Review unresolved PR comments and take action on each one: address valid feedback with a code fix,
  commit, push, and reply with a linkified commit hash; dismiss invalid feedback with a clear explanation.
  Trigger when the user says things like "respond to review comments", "handle Copilot feedback",
  "address PR comments", or "reply to review".
argument-hint: "[PR number (defaults to the current branch's PR)]"
---

# PR Review Comment Workflow

## Step 1: Identify the PR and repository

- If `$ARGUMENTS` is provided, use that PR number.
- Otherwise, run `gh pr view --json number,headRepository` to detect the current branch's PR.

## Step 2: Fetch unresolved review comments

Use the GitHub MCP `pull_request_read` tool (method: `get_review_comments`).
Skip threads where `is_outdated: true` — they're already addressed.

## Step 3: Act on each comment

### Address it (valid feedback)

1. Make the code change.
2. Run lint / typecheck to confirm no errors.
3. `git add` → `git commit` → `git push`
4. Reply using `gh api --method PATCH repos/{owner}/{repo}/pulls/comments/{id}` with this format:

   > Fixed in ([`abc1234`](https://github.com/{owner}/{repo}/commit/{full_hash})). {one-line summary of what changed}.

   Always linkify the hash — never leave it as plain text.

### Dismiss it (not needed)

Reply via `add_reply_to_pull_request_comment` with a concise technical rationale.
Be direct but not dismissive — explain *why* the change isn't necessary.

## Conventions

- Use `git rev-parse HEAD` after push to get the full commit SHA for the link.
- If multiple comments are addressed in one commit, reply to each with the same link.
- Reply format for fixes: `Fixed in ([{short_hash}]({url})). {explanation}.`
