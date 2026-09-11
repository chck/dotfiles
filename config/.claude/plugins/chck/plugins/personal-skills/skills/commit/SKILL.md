---
name: commit
description: Stage all changes and create a git commit. Use after finishing an implementation task.
disable-model-invocation: true
argument-hint: "[commit message (optional)]"
---

Stage all unstaged changes and create a git commit.

## Steps

1. Run `git status` and `git diff` to understand what changed
2. Run `git log --oneline -5` to follow the existing commit message style
3. Stage files: prefer `git add <specific files>` over `git add -A`; never stage `.env` or credential files
4. If `$ARGUMENTS` is provided, use it as the commit message body
5. Otherwise, generate a message following the repository's conventions:
   - Use Conventional Commits format: `type(scope): description`
   - Common types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
   - Keep the subject line under 72 characters
   - Append the host's canonical co-author trailer in step 6
6. Append exactly one co-author trailer unless the message already contains one:
   - Claude Code → `Co-Authored-By: Claude <noreply@anthropic.com>`
   - Codex → `Co-Authored-By: Codex <noreply@openai.com>`
   Keep `Claude` or `Codex` in the display name even when the model has a more
   specific name; the repository quality metrics use that host name as the
   agent footprint.
7. Commit and show the result with `git log -1 --stat`
