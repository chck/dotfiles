# Kitesurf

Installs the experimental terminal client, not a local engine or a Cloudflare
deployment. Rust 1.96+ is required. The install is guarded by the executable;
upgrade explicitly with:

```sh
cargo install --git https://github.com/cloudflare/kitesurf.git --locked kitesurf
```

## Use with agents

| Task | Tool |
| --- | --- |
| HTTP, documentation, HTML extraction | `ax` |
| Local file names / contents | `fd` / `rg` |
| Terminal browsing, experiments with the Kitesurf engine | `kitesurf` |
| Routine web interaction | Orca embedded browser in Orca; otherwise `agent-browser` |
| Native apps and browser GUI beyond page content | `orca-computer-use` |

Kitesurf parses HTML, applies CSS and runs JavaScript in its own engine. Its CLI
plays rendered scenes using Kitty graphics or ANSI text. It does not expose an
agent-oriented snapshot/ref or JSON extraction interface. CDP compatibility is
partial, so connecting an existing Chrome client does not establish that every
command works. Treat Kitesurf checks separately from Chrome compatibility tests.

On 2026-11-17, CLI 0.0.5 rendered a public page through the playground, and
agent-browser connected to its CDP endpoint and successfully ran `open`,
`snapshot`, `get cdp-url` and `get text body`. For an explicit experiment, use a
dedicated session and close it afterwards:

```sh
agent-browser skills get core
agent-browser --session kitesurf-probe --cdp wss://kitesurf.dev/devtools/browser open https://example.com/
agent-browser --session kitesurf-probe snapshot
agent-browser --session kitesurf-probe get text body
agent-browser --session kitesurf-probe close
```

This verifies those basic operations only, not forms, authentication, complex
SPAs or full Chrome/CDP compatibility. The playground can change independently
of the installed client. Agent-browser may identify its advertised Chrome user
agent as outdated; that does not mean it connected to a local Chrome instance.

Start with a public page on the credential-free playground:

```sh
kitesurf --playground --mode=ansi https://example.com/
```

For a finite connection/rendering smoke check without terminal graphics:

```sh
kitesurf --playground --no-display --seconds 5 https://example.com/
```

Without `--playground`, opening a URL uses Cloudflare Browser Run and starts OAuth
if needed. The CLI stores the login in the OS credential store. Keep account IDs
and tokens out of dotfiles; CLI environment overrides belong in local shell
configuration. Do not send authenticated/private pages to the public playground.

A remote engine has its own network and cookies: it cannot access this machine's
localhost or the user's signed-in Chrome session. For local development, build
and start the engine separately, then select it explicitly:

```sh
KITESURF_SERVER=http://127.0.0.1:8799 kitesurf http://127.0.0.1:3000/
```

Nothing here auto-starts a server, claims a port, registers MCP, changes Orca's
browser, or shares browser profiles. Global routing lives in `config/AGENTS.md`;
the Orca and agent-browser skills remain upstream-managed through apm.

## Upstream references

- [Engine requirements, local setup, CDP and deployment](https://github.com/cloudflare/kitesurf#readme)
- [CLI installation, modes and authentication](https://github.com/cloudflare/kitesurf/blob/main/packages/kitesurf-cli/README.md)
