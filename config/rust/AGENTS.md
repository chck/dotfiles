# Rust-specific Instructions

## Code style
- Keep `cargo fmt` clean and `cargo clippy` warning-free
- Avoid `unwrap()`/`expect()` in non-test code — propagate errors with `Result` and `?`

## Preferred crates
- Reach for these de-facto standards before rolling your own or picking alternatives:
  - Serialization: `serde` + `serde_json`
  - Error handling: `anyhow` (applications), `thiserror` (libraries)
  - Async runtime: `tokio`
  - HTTP client: `reqwest` (async, `features = ["rustls-tls"]`); `ureq` for lightweight sync
  - CLI parsing: `clap` (derive)
  - Regex: `regex`
  - Data parallelism: `rayon`
  - Logging: `log` + `env_logger` (simple); `tracing` (structured, e.g. web backends)
