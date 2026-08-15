# Python-specific Instructions

## Package management
- Use `uv`. Add deps with `uv add <pkg>` (dev: `uv add --dev <pkg>`), run with `uv run <cmd>`
- Never `pip install` — `pyproject.toml` + `uv.lock` are the source of truth
- Pin the interpreter range in `requires-python` (e.g. `>=3.12,<3.15`), not just a floor
- `src/` layout: package lives in `src/<pkg>/`, built with `hatchling`
- Version from git tags: `uv-dynamic-versioning` as `[tool.hatch.version] source`, bumps/CHANGELOG via `commitizen`
- Dev tools (ruff, ty, pytest, pre-commit) belong in `[dependency-groups] dev`, not a global install

## Lint / Format / Type check
- `ruff` for both lint and format. Do not use black / isort / flake8
- Configure in `pyproject.toml`: `line-length = 120`, `lint.fixable = ["ALL"]`
- Baseline `lint.select`: `["W", "E", "F", "S", "B", "C4", "I", "C90", "N", "UP", "ARG001"]`
  - On a new or noisy project, start at `["E", "W", "F", "I", "UP", "B"]` and tighten incrementally
- Per-file ignores: `"tests/**" = ["S101"]` (assert). Exclude notebooks with `extend-exclude = ["*.ipynb"]`
- Type check with `ty` (Astral): `uv run ty check`. Do not add mypy to new projects
  - `[tool.ty.terminal]`: `error-on-warning = true`, `output-format = "full"`
- Wire ruff-check / ruff-format / ty as local `pre-commit` hooks so CI and local runs match

## Testing
- Use pytest (not unittest). Place tests under `tests/` and set `testpaths = ["tests"]`
- Name test modules after their target: `domain/bot.py` → `tests/test_domain_bot.py`
- Dev deps: `pytest-cov`, `pytest-mock`, `pytest-xdist` (`pytest-sugar` optional)
- Add tests for new behavior — cover success, failure, and edge cases
- Use `@pytest.mark.parametrize` for multiple similar inputs

## Libraries
- Data structures and settings: Pydantic v2 / `pydantic-settings` — model domain types with Pydantic, not bare dict/dataclass
- Web API: FastAPI + uvicorn / CLI: Typer / HTTP: httpx (not requests)
- DataFrames: Polars; use pandas only where an external API requires it
- Terminal output: rich

## Code style
- Add type annotations to all new code
- No docstrings unless explicitly requested
- Follow the layered/DDD dependency direction: presentation → usecase → domain; external concretes live in `adapter/`

## Commands
- cargo-make (`makers`) is the entrypoint: `makers lint` / `makers format` / `makers typecheck` / `makers test`
- Underlying commands: `uv run ruff check --fix .`, `uv run ruff format .`, `uv run ty check .`, `uv run pytest`
- Application/job entrypoints go in `[tool.taskipy.tasks]` with a `help` string, invoked via `uv run task <name>`
