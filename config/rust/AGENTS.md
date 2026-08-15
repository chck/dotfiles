# Rust-specific Instructions

## Toolchain / Project layout
- Pin the toolchain with `rust-toolchain.toml`: `channel = "stable"`, `components = ["rustfmt", "clippy"]`
- Use `edition = "2024"` for new crates
- Map the layered/DDD structure onto workspace member crates (`domain`, `usecase`, `adapter`, `api`, `shared`),
  wired together by a `registry` crate — the dependency direction is enforced by the crate graph
- Centralize versions in `[workspace.dependencies]`; members refer to them as `<dep>.workspace = true`
- A crate that must *not* be absorbed by a parent workspace needs an explicit empty `[workspace]` table —
  without it, placing the repo under another workspace (git worktree, nested checkout) fails with
  "current package believes it's in a workspace when it's not"

## Code style
- Keep `cargo fmt` clean and `cargo clippy` warning-free
- Avoid `unwrap()`/`expect()` in non-test code — propagate errors with `Result` and `?`

## Testing
- Put tests in the crate's `tests/` directory rather than inline `#[cfg(test)]` modules
- Mock domain traits with `mockall`'s `#[automock]`; use `tokio-test` for async tests

## Commands
- cargo-make (`makers`) is the entrypoint; underlying commands:
  - `cargo fmt --all`
  - `cargo clippy --all --all-targets` locally, `cargo clippy -- --no-deps -D warnings` in CI
  - `cargo test`

## Preferred crates
- Reach for these de-facto standards before rolling your own or picking alternatives:
  - Serialization: `serde` + `serde_json`
  - Error handling: `anyhow` (applications), `thiserror` (libraries)
  - Async runtime: `tokio`
  - Web server: `axum` (+ `tower-http` for CORS/trace); OpenAPI via `utoipa`
  - HTTP client: `reqwest` (async, `features = ["rustls-tls"]`); `ureq` for lightweight sync
  - Database: `sqlx` (compile-time checked queries, `runtime-tokio`)
  - CLI parsing: `clap` (derive)
  - Validation: `garde` (derive)
  - Date/time: `chrono` (`features = ["serde"]`); IDs: `uuid` (v7) or `ulid`
  - Regex: `regex`
  - Data parallelism: `rayon`
  - Logging: `log` + `env_logger` (simple); `tracing` + `tracing-subscriber` (structured, e.g. web backends)
