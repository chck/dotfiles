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
| `brew install --cask` | GUI applications |
| `brew install` | CLI tools not in the mise registry, and build dependencies (openssl, cmake, pkg-config) |
| mise | Language runtimes, anything whose version you want to control, and any CLI in `mise registry` |
| `cargo` | `cargo-*` subcommands and crates that should track the Rust toolchain |
| `github_binary` | One-off binaries available in no registry |

Decide in this order: GUI app → cask. Version needs controlling → mise. Otherwise
check `mise registry <name>`, then fall back to `brew`, then `github_binary`.

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

## What belongs in this repository

This repository is public. Committed files must contain no secrets and nothing
specific to one machine.

| Location | Tracked | Contents |
|----------|---------|----------|
| `config/mise/config.toml` | yes | Global tool list |
| `~/.config/mise/conf.d/*.toml` | no | Machine-local tools, pinned versions, `[env]` secrets |

mise reads `conf.d/*.toml` alongside `config.toml`, so local additions need no
changes here and never risk being committed. The same split applies generally:
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
