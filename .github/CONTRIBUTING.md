# Contributing

## Prerequisites

- macOS
- [Homebrew](https://brew.sh/)
- Git

## Setup

```shell
git clone --recursive https://github.com/chck/dotfiles.git
cd dotfiles
```

### pre-commit hooks

```shell
mise use --global pre-commit@latest
pre-commit install
```

## Development

### Dry-run before applying

```shell
./install.sh -n
```

### Apply changes

```shell
./install.sh
```

## Adding a new cookbook

1. Create the cookbook directory and recipe:

```shell
mkdir cookbooks/:app_name
$EDITOR cookbooks/:app_name/default.rb
```

2. Register it in the role for your platform:

```shell
$EDITOR roles/$(uname)/default.rb
```

### Cookbook structure

```
cookbooks/:app_name/
└── default.rb   # mitamae recipe
```

Refer to existing cookbooks (e.g. `cookbooks/bat/`, `cookbooks/awscli/`) as examples.

## Choosing an install method

| Method | Use for |
|--------|---------|
| apm | Agent skills and MCP servers |
| `brew install --cask` | GUI applications |
| `brew install` | CLI tools not in the mise registry, and build dependencies (openssl, cmake, pkg-config) |
| mise | Language runtimes, anything whose version you want to control, and any CLI in `mise registry` |
| `cargo` | `cargo-*` subcommands and crates that should track the Rust toolchain |
| `github_binary` | One-off binaries available in no registry |

Decide in this order: agent skill or MCP server → apm. GUI app → cask. Version
needs controlling → mise. Otherwise check `mise registry <name>`, then fall back
to `brew`, then `github_binary`.

A package published as a Claude Code **plugin** still goes to apm when it ships
skills and nothing else — apm deploys it to `~/.agents/skills/` as well, so codex
and the other agents get it too, which the plugin system cannot do.
`mattpocock/skills` is carried that way.

Reach for the plugin system only when the package carries something apm drops.
apm deploys `skills/` alone, so a plugin's commands and hooks are lost:
diagram-design's `/export-diagram` and `/doctor`, caveman's `${CLAUDE_PLUGIN_ROOT}`
hooks. The same applies to a package runtime — claude-mem builds from npm, and
claude-code-wakatime shells out to a self-installing `wakatime-cli`. Those are
registered by `cookbooks/claude`.

aqua is installed by `cookbooks/aqua` but manages no packages here on purpose.
Its strength is per-repository pinning with checksum verification, which does not
fit a repo whose job is building one global environment. Use it inside individual
project repositories; keep dotfiles' global tools in mise.

### Adding a mise-managed tool

Add one line to `config/mise/config.toml`. Do **not** write `mise use --global`
in a cookbook: that file is symlinked to `~/.config/mise/config.toml`, so the
command would rewrite a tracked file and show up as a diff.

For the same reason every entry stays on `"latest"` — the `up` alias runs
`mise up --bump`, which rewrites pinned versions in place.

### Adding an agent skill or MCP server

Add an entry to `config/apm/apm.yml`, which is symlinked to `~/.apm/apm.yml` and
applied by `apm install -g` from `cookbooks/claude`. Skills land in
`~/.config/claude/skills/`, MCP servers in `~/.config/claude/.claude.json`.

```yaml
dependencies:
  apm:
    - owner/repo/skills/<name>          # a skill inside a repo
    - ~/absolute/path/to/package        # a skill kept locally
  mcp:
    - name: <server>
      transport: stdio
      command: uvx
      args: [...]
```

As with mise, edit the file by hand and then run bare `apm install -g`. Passing a
package (`apm install -g <pkg>`) rewrites the manifest and shows up as a diff.

Two failure modes are worth knowing, because **both fail silently and
`apm install --dry-run` reports success in either case**:

- A local package needs its own `apm.yml`. Without one, apm resolves the path,
  reports it as installed, and deploys nothing.
- A local path must be absolute or `~`-expanded. A relative path resolves
  against `~/.apm/` rather than the manifest, and fails the same silent way.

After changing the manifest, count what actually landed in
`~/.config/claude/skills/` rather than trusting the exit code.

Dependencies are intentionally unpinned, so `apm install -g` follows upstream.
Use `apm outdated -g` to see drift and `apm update -g` to refresh. Pinning is
possible (`#<tag>`) but `apm update` will then skip that entry, and a `#<sha>`
pin also makes `apm outdated` report `unknown` — you lose any signal that an
update exists.

## What belongs in this repository

This repository is public. Committed files must contain no secrets and nothing
specific to one machine.

| Location | Tracked | Contents |
|----------|---------|----------|
| `config/mise/config.toml` | yes | Global tool list |
| `~/.config/mise/conf.d/*.toml` | no | Machine-local tools, pinned versions, `[env]` secrets |
| `config/apm/apm.yml` | yes | Skill and MCP declarations |
| `~/.apm/apm.lock.yaml` | no | Resolved commits and deployment state |

mise reads `conf.d/*.toml` alongside `config.toml`, so local additions need no
changes here and never risk being committed.

The apm lockfile stays untracked on purpose. It is stable and holds no secrets,
so committing it would be safe, but it only takes effect with
`apm install --frozen`, which refuses to install whenever the lockfile and
manifest disagree — every manifest edit would then have to be paired with a
lock refresh before `./install.sh` could run. Reproducibility here is not worth
that, given the manifest deliberately follows upstream.

The same split applies generally:
if a config file is rewritten by the tool that owns it, or holds credentials,
keep it out of `config/` and let the local override mechanism handle it.

## Commit conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>
```

Common types: `feat`, `fix`, `chore`, `docs`, `refactor`

Examples:
- `chore(zsh): add new alias`
- `feat(cookbooks): add ripgrep cookbook`
- `fix(install): correct submodule init path`

## Pull requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-change`
3. Make changes and verify with a dry-run
4. Push and open a pull request against `main`

## pre-commit checks

The following checks run automatically on commit:

| Stage | Hook |
|-------|------|
| pre-commit | Trailing whitespace |
| pre-commit | End-of-file newline |
| pre-commit | Line endings normalized |
| pre-commit | YAML / JSON / TOML syntax |
| pre-commit | JSON auto-formatting |
| pre-commit | Executable files have shebangs |
| pre-commit | No merge conflict markers |
| pre-commit | No private keys |
| pre-commit | Large file guard (≤ 100 MB) |
| commit-msg | Conventional Commits format (commitizen) |

> JSON syntax and formatting checks skip `config/settings.json` because it is JSONC (contains comments).
