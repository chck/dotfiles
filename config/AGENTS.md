# Coding Agent Instructions

## Tech Stack
- Backend (in order): Python, Rust
- Frontend (in order): TypeScript with Vite+, HTMX
- Infrastructure: Terraform with OpenTaco (ex. digger)

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

## Commands
- Use cargo-make as command launcher, alias is `makers`
- Show all commands: `makers help`
- Enable commit hooks: `pre-commit install`

## Testing
- Use pytest (not unittest)
- Place tests under `tests/`

## Code style
- Add type annotations to new code
- No docstrings unless explicitly requested
- Prefer minimal, focused changes — don't refactor surrounding code

## Response style
- Be concise — skip preamble and trailing summaries
- No emojis unless asked
- Reference code as `file_path:line_number`

## Security
- Never read or commit files matching: `*.env`, `*.key`, `*.pem`, `*secret*`, `*password*`, `*credential*`
