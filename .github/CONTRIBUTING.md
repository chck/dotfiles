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
brew install pre-commit
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
| pre-commit | YAML / JSON / TOML syntax |
| pre-commit | Executable files have shebangs |
| pre-commit | No merge conflict markers |
| pre-commit | No private keys |
| pre-commit | Large file guard (≤ 1 MB) |
| commit-msg | Conventional Commits format (commitizen) |
