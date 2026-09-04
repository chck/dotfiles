---
name: git-wt
description: >
  Use the git-wt command to create an isolated Git worktree for a task, keeping the main branch clean.
  After finishing, delete the worktree — always and without asking once the branch is merged.
  Use for every change that touches a file — including single-file edits, typo fixes, and
  documentation-only changes — and whenever the user explicitly requests worktree isolation
  ("use a worktree", "use wt", "work on a separate branch", "isolate this in a worktree").
---

# Git Worktree Workflow

Use `git-wt` to create a worktree and do all work there, keeping the main branch untouched.
If anything goes wrong, `git wt -d` cleanly removes the worktree and branch.

## Step 1: Create the worktree

Choose a branch name from the task, then branch from `origin/main` — never from the current
HEAD, which a concurrent session sharing this checkout may have moved:

```bash
git fetch origin
git wt <branch-name> origin/main --nocd
```

The worktree is created at `.worktrees/<branch-name>/`. Record the printed path as `WORKTREE_PATH`.

Substitute the repository's default branch if it is not `main` (e.g. `origin/master`).
The new branch tracks `origin/main`, so push it with `-u origin <branch-name>` (see Step 3).

## Step 2: Do all work inside the worktree

Every operation must target `WORKTREE_PATH`:

- Read/Edit/Write tools: use absolute paths like `$WORKTREE_PATH/src/...`
- Bash commands: `cd $WORKTREE_PATH && <command>`

## Step 3: Report completion

When done, tell the user:
- What files changed and a brief summary
- The worktree path
- How to merge (e.g., `cd $WORKTREE_PATH && git push -u origin <branch-name>` → open a PR)

## Step 4: Clean up

Check the branch state first, then act. No merged worktree is ever left behind.

### Merged branch — delete, never ask

Once the PR is merged (or the commits are in `origin/main`), remove the worktree and the branch
without asking, every time — single-file, typo, and documentation-only branches included.

```bash
gh pr view <branch-name> --json state,mergedAt   # state "MERGED" → safe to delete
git wt -D <branch-name>
```

`-D`, not `-d`: a squash merge rewrites the commits, so the local branch never becomes an ancestor
of `origin/main` and `git wt -d` refuses it as unmerged. Confirm `state: MERGED` before running
`-D` — on a branch that was not merged, `-D` discards its commits.

`gh pr merge --delete-branch` fails in this layout with
`fatal: 'main' is already used by worktree at ...`: it tries to check the default branch out in the
current worktree. Merge with `gh pr merge <number> --squash --repo <owner>/<repo>`, then delete the
local side with `git wt -D`.

### Unmerged, no changes (nothing committed or modified)

Delete automatically — no need to ask the user.

```bash
git wt -d <branch-name>
```

### Unmerged with changes or commits

Ask the user: **keep** or **delete**?

- **Keep**: leave the worktree and branch as-is. Let the user know they can return with `cd $WORKTREE_PATH`.
- **Delete**: warn that uncommitted changes and commits will be lost, then delete only if the user confirms.

```bash
git wt -D <branch-name>
```

### Repositories with submodules

`git wt -d` fails with `fatal: could not reset submodule index` when the repository has
submodules that were never initialized in the worktree. The worktree is still there afterwards.
Remove it directly instead, then drop the branch:

```bash
git worktree remove --force .worktrees/<branch-name>
git branch -d <branch-name>          # -D if the branch is unmerged
```

`--force` here discards nothing beyond the worktree directory itself — commits already pushed
are on the remote, and the branch is deleted separately.

Two more commands need `--ignore-submodules=all` in such a repository, for the same reason:

```bash
git status --short --ignore-submodules=all
git diff --stat --ignore-submodules=all
```

Do not run `git checkout -- .` there: it aborts on the submodule index and may leave the revert
half-applied. Revert named files instead.

## Branch naming

| Type | Prefix | Example |
|------|--------|---------|
| Feature / change | `feat/` | `feat/add-dark-mode` |
| Bug fix | `fix/` | `fix/image-upload-error` |

When linked to an issue, include the issue number: `feat/16-add-dark-mode`, `fix/20-image-upload-error`.

## Parallel multi-agent work

When spawning multiple subagents with the Agent tool, give each its own branch and worktree:

```bash
git wt feat/feature-a origin/main --nocd  # → .worktrees/feat/feature-a
git wt feat/feature-b origin/main --nocd  # → .worktrees/feat/feature-b
```

Pass each agent its explicit worktree path so they don't step on each other.
