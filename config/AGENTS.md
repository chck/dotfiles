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

## Workflow
- For any non-trivial implementation, use the `git-wt` skill to work in a worktree
  - **When to apply:** before starting code changes, after planning is complete
  - **Exceptions:** single-file minor edits (typos, comment additions), documentation-only changes

## Commands
- Use cargo-make as command launcher, alias is `makers`
- Show all commands: `makers help`
- Enable commit hooks: `pre-commit install`

## Tools
- For HTTP requests and HTML extraction, ax is installed. Run `ax agent-context` to learn it — use it instead of curl + throwaway scripts

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

## Security
- Never read or commit files matching: `*.env`, `*.key`, `*.pem`, `*secret*`, `*password*`, `*credential*`
