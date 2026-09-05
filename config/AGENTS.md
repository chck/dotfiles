# Coding Agent Instructions

## Tech Stack
- Backend (in order): Python, Rust
- Frontend (in order): TypeScript with Vite+, HTMX
- Infrastructure: Terraform with OpenTaco (ex. digger)

## Language-specific rules
- Rules that apply only to a given language live in a sibling file. Read the
  relevant one **before** writing code in that language:
  - Python → `python/AGENTS.md` (next to this file)
  - Rust → `rust/AGENTS.md` (next to this file)
  - JavaScript / TypeScript / Node → `javascript/AGENTS.md` (next to this file)

## Design Pattern
- Layered Architecture with Domain-driven design (DDD)
```
src/app_name
├ presentation/  ... Presentation Layer (Interface for external requests, handles routing and input parsing)
│  ├ api/        ... Web API endpoints (FastAPI, Flask, etc.)
│  └ cli/        ... Command-line interface (Typer, Click, argparse, etc.)
├ usecase/     ... Application Layer (Coordinates business workflows and orchestrates domain operations)
├ domain/      ... Domain Layer (Core data structures (Pydantic) and pure business rules)
├ adapter/     ... Infrastructure Layer / Adapters (Concrete implementations for DB, external APIs, notifications)
├ shared/      ... Shared (Common utilities and helper functions)
└ __main__.py    ... Execution entry point (Application bootstrap and configuration)
```

## Domain types
- A domain type carries its own invariants. A type that is nothing but fields,
  with the rules living in `usecase/`, is an anemic model — put the rule on the type
- Validate at construction, so that a value which exists is a value which is valid
- Prefer making an illegal state unrepresentable to validating it away: a separate
  type over a flag, an enum over a pair of bools, a narrow type over a bare string
- An invariant stated only in a docstring or a comment is not enforced
- Do not expose mutable internals; prefer immutable domain values

## Error handling
- Never swallow an error. A handler that logs nothing and changes nothing hides
  the failure from whoever has to debug it later
- Catch the specific error this code can act on. A broad catch also swallows the
  bugs you did not anticipate
- A fallback is a decision, not a default. It has to be asked for, and the caller
  must be able to tell a fallback result from a real one
- Propagate when this layer cannot act on the error — handle it where the decision
  belongs, usually a boundary rather than the middle
- Never fall back to a mock, stub, or fixture outside test code
- An error message states what failed and what the reader can do next

## Workflow
- Always use the `git-wt` skill to work in a worktree — including single-file
  edits, typo fixes, and documentation-only changes. There are no exceptions
  - **When to apply:** before touching any file, after planning is complete
  - **Base the branch on `origin/main`** (fetch first), not on the current HEAD
  - **Why:** a checkout can be shared with other concurrent sessions. Committing
    on the shared HEAD lands the commit on whatever branch that session switched
    to, and `git switch` / `reset` there can disturb its uncommitted work
- Subagents are always permitted. Use the Agent tool whenever it fits — parallel
  independent tasks, broad searches, per-task execution of a plan — without asking
  first. This overrides any default that says to only use it when explicitly requested.
  - Default execution mode after `writing-plans` is Subagent-Driven; do not ask which mode to use

## Commands
- Use cargo-make as command launcher, alias is `makers`
- Show all commands: `makers help`
- Enable commit hooks: `pre-commit install`

## Tools
- For HTTP requests and HTML extraction, ax is installed. Run `ax agent-context` to learn it — use it instead of curl + throwaway scripts
- For searching file contents, use ripgrep (`rg`) instead of `grep` — it is faster and respects `.gitignore`
- For finding files by name, use `fd` instead of `find` — it is faster and respects `.gitignore`
- Before reading a large source file, run `zat <file>` — it prints top-level declarations with their line numbers, so you can then read only the ranges you need. One file per run, no flags, no directories; C/C++/C#/Go/Haskell/Java/JS/TS/Kotlin/Markdown/Python/Ruby/Rust/Swift only, not shell

## Code style
- Add type annotations to new code
- Prefer minimal, focused changes — don't refactor surrounding code

## Response style
- Be concise — skip preamble and trailing summaries
- No emojis unless asked
- Reference code as `file_path:line_number`

## Git
- Commit messages describe **what changed**, not why or who asked
  - Bad: `fix review comments`, `address feedback`, `PR response`
  - Good: `fix: add null check to prevent undefined access`
- Always add a co-author trailer to commits you (the agent) create, naming the model you are running as:
  - `Co-Authored-By: <your model display name> <noreply@anthropic.com>`
  - e.g. `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`
  - If you cannot tell which model you are, use `Claude`

## Security
- **Secret material** — the contents of `*.env`, `*.key`, `*.pem`, a private key block, an
  access token, a live password. Do not open one to read the value, do not copy a value
  elsewhere, never commit one. On finding a stray one, report the path and the kind of
  credential without reproducing the value
- **Source that handles secrets** — `secret_manager.ts`, `password.py`, `credentials.go`,
  `03_parameter.tf`. Ordinary code: read it, review it, change it. Excluding a file because its
  *name* contains `secret` hides the code most worth reading. Mask any literal value quoted out
  of one
- **Writing into a public repository** — check `gh repo view --json visibility` before posting.
  A PR body, issue body, or comment on a public repository is world-readable, and so is its
  edit history: removing text later leaves the original revision viewable. Do not name a
  private or internal org, repository, or cross-reference one by link — describe the situation
  without the identifier instead
