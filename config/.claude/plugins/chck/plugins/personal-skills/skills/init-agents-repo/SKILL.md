---
name: init-agents-repo
description: Lay out a repository so every coding agent reads one canonical AGENTS.md. Use when creating a repository, when only CLAUDE.md exists, when adding Codex/Copilot/Gemini to a repo that Claude Code already works in, or when the user says "multi agent 対応", "AGENTS.md に寄せる", "init agents repo", or "エージェント共通の定義にして".
---

# Init multi-agent repository layout

Make `AGENTS.md` the single source of truth for agent instructions, and let each host reach it
through the file name that host looks for. Only use this in repositories the user owns.

## What each host reads

Every host looks for a different file name, so a naive layout puts `AGENTS.md`, `CLAUDE.md` and
`GEMINI.md` side by side in the root. Only the first one has to be there. Keep the root at one
instruction file and give each host an entry point in its own directory.

| Host | Entry point | How it reaches `AGENTS.md` |
|---|---|---|
| Codex | `AGENTS.md` (root) | reads it directly |
| Claude Code | `.claude/CLAUDE.md` | a `@../AGENTS.md` import line |
| Gemini CLI | `.gemini/settings.json` | `context.fileName` lists `AGENTS.md` |
| GitHub Copilot | `.github/copilot-instructions.md` | symlink |

`AGENTS.md` cannot leave the root. Codex walks root-to-cwd against an allowlist of file *names*
and has no import syntax, and Copilot's repository-level surfaces (cloud agent, code review,
github.com chat) take no path configuration. A root symlink into `.agents/` is the only trick
left, and no host documents symlink-following for instruction files — do not rely on it.

Claude Code does **not** read `AGENTS.md`, which is why an entry point is needed at all. Its
`@path` import resolves relative to the importing file, nests up to 4 hops, and works on every
OS. Prefer the import over a symlink: it survives a Windows checkout and leaves room for
Claude-only rules underneath.

## Steps

1. **Survey what is already there** — `ls` for `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`,
   `.github/copilot-instructions.md`, and `.cursor/rules/`. Never overwrite an existing file
   without saying what will be lost and getting confirmation.

2. **Establish the canonical file.**
   - `CLAUDE.md` has content and no `AGENTS.md`: `git mv CLAUDE.md AGENTS.md`
   - both exist with different content: show the difference and ask which one wins, or merge
   - neither exists: write `AGENTS.md` from the skeleton below, filled in from the repository
     (read the build files, CI config, and directory layout first — do not ask what you can read)

   After a rename, **fix the file's own text**: the title, any sentence naming a single host
   ("guide for Claude Code"), and every reference to the old path elsewhere in the repository.
   A renamed file that still calls itself `CLAUDE.md` is the most common leftover.

3. **Point Claude Code at it.** Write `.claude/CLAUDE.md` as a single import line:

   ```markdown
   @../AGENTS.md
   ```

   Add a `## Claude Code specific` section below it only when there is something host-specific
   to say (a skill to prefer, a permission note). Keep shared rules in `AGENTS.md`.

4. **Set up the remaining hosts**, but only the ones the user actually uses — ask which ones:

   ```bash
   # Gemini CLI — reads context.fileName, so no file in the root
   mkdir -p .gemini
   printf '{\n  "context": {\n    "fileName": [\n      "AGENTS.md"\n    ]\n  }\n}\n' > .gemini/settings.json

   # GitHub Copilot
   mkdir -p .github && ln -s ../AGENTS.md .github/copilot-instructions.md
   ```

   `context.fileName` also accepts an array and a directory-qualified path, so an existing
   `GEMINI.md` can stay listed alongside `AGENTS.md`.

5. **Consider the neighbours** — propose each, create only what the user wants:
   - `.claude/skills/<name>/` for skills that belong to this repository. Claude Code discovers
     skills here and nowhere else; a `skills/` directory at the root is not read
   - `.mcp.json` for MCP servers the repository needs, committed so everyone gets them
   - `.worktreeinclude` listing gitignored files to copy into new worktrees (`.env`, local
     config) — worth it in any repository where work happens in worktrees

6. **Verify, do not assume.** Put a unique marker in `AGENTS.md`, ask each installed host for
   it from the repository root, then remove the marker.
   - `claude -p "What marker string appears in the project instructions?" --output-format json`
   - `gemini --skip-trust -p "What marker string appears in the project instructions?"`
   - `git ls-files -s .github/copilot-instructions.md` — mode must be `120000`, otherwise git
     stored a copy instead of a link
   - hosts that are not installed cannot be verified. Say so instead of implying they work

7. **Report** the files created, which hosts are covered, and what was left out.

## Notes

- Commit every one of these files. They are part of the repository contract, not local setup
- Do not add the host files to `.gitignore`. A gitignored `CLAUDE.md` defeats the whole layout
- Symlinks need `core.symlinks` on a Windows checkout. Only Copilot's entry point is a symlink
  in this layout; if the repository has Windows users, replace it with a one-line stub that
  points at `AGENTS.md`
- A symlinked `~/.claude/CLAUDE.md` is skipped in Cowork desktop sessions. That affects the
  user-level dotfiles setup, not repository-level files
- Keep `AGENTS.md` about the repository. Personal preferences belong in the user-level file

## AGENTS.md skeleton

Fill each section from the repository. Delete sections that do not apply — an empty heading is
worse than no heading.

````markdown
# <repo name>

<one or two lines: what this repository is, who runs it>

## Stack
- Language / runtime:
- Framework:
- Infrastructure:

## Layout
<the directories that matter and what belongs in each>

## Commands
```shell
<install>
<test>
<lint>
<run>
```

## Conventions
- <naming, typing, error handling — only rules an agent would otherwise get wrong>

## Workflow
- <branching, review, how changes reach production>

## Security
- <files never to read or commit, secret handling>
````
