---
name: review-pr-comments
description: >
  Review unresolved PR comments and take action on each one: address valid feedback with a code fix,
  commit, push, and reply with a linkified commit hash; dismiss invalid feedback with a clear explanation.
  Then resolve each thread you replied to (GraphQL resolveReviewThread) so the conversation is marked resolved.
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

Also fetch the **review-thread node IDs** (needed to resolve threads in Step 4 —
the REST comment API doesn't expose them). Query them once with GraphQL:

```bash
gh api graphql -f query='
  query($owner:String!,$repo:String!,$pr:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$pr){
        reviewThreads(first:100){
          nodes{
            id
            isResolved
            isOutdated
            comments(first:1){ nodes{ databaseId path } }
          }
        }
      }
    }
  }' -f owner={owner} -f repo={repo} -F pr={pr}
```

Map each comment's `databaseId` to its thread `id`; skip threads already
`isResolved: true`.

## Step 3: Act on each comment

Reply to a review comment with a **threaded reply** — never `PATCH .../pulls/comments/{id}`,
which *edits the reviewer's own comment* and destroys their feedback. Use the MCP
`add_reply_to_pull_request_comment` tool, or the REST replies endpoint:

```bash
gh api --method POST repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies -f body='...'
```

### Address it (valid feedback)

1. Make the code change.
2. Run lint / typecheck to confirm no errors.
3. `git add` → `git commit` → `git push`
4. Post a threaded reply (see above) with this format:

   > Fixed in ([`abc1234`](https://github.com/{owner}/{repo}/commit/{full_hash})). {one-line summary of what changed}.

   Always linkify the hash — never leave it as plain text.

### Dismiss it (not needed)

Post a threaded reply with a concise technical rationale.
Be direct but not dismissive — explain *why* the change isn't necessary.

## Step 4: Resolve the conversation

After replying — whether the comment was addressed or dismissed — resolve its
thread so the "Resolved" checkbox is ticked and the conversation collapses.
There is no REST endpoint for this; use the GraphQL `resolveReviewThread`
mutation with the thread `id` from Step 2:

```bash
gh api graphql -f query='
  mutation($threadId:ID!){
    resolveReviewThread(input:{threadId:$threadId}){
      thread{ id isResolved }
    }
  }' -f threadId={thread_node_id}
```

Confirm the response shows `isResolved: true`. Resolve only threads you actually
replied to in this run — never mass-resolve unaddressed feedback.

## Conventions

- Use `git rev-parse HEAD` after push to get the full commit SHA for the link.
- If multiple comments are addressed in one commit, reply to each with the same link.
- Reply format for fixes: `Fixed in ([{short_hash}]({url})). {explanation}.`
- Commit messages must describe the actual changes — never use vague summaries like
  "address review feedback" or "fix review comments". Each commit should say exactly
  what changed, e.g. `fix(ci): add pull-requests:read to plan workflow`.
