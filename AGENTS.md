# Agent Instructions

Repository-local rules for this dotfiles repo. These override the global
instructions deployed from `config/AGENTS.md`.

## The one rule that matters

`config/` is the source. Everything under `$HOME` is a deployed artifact.

Before editing any config file, resolve which side you are on. Editing the live
path is either invisible (it is a symlink into this repo, so the edit silently
becomes an uncommitted change here) or discarded (it is a copy, so the next
provision overwrites it). Neither failure surfaces as an error.

### Reverse lookup: live path → source

```shell
ls -l <live-path>                     # symlink? the target is the source
rg -n '<basename>' cookbooks/ config/apm/apm.yml   # otherwise find who deploys it
```

Never conclude a file is untracked from `git -C <dir-under-$HOME> rev-parse`.
Search this repository instead — most of `$HOME`'s config originates here.

## Deploy mechanisms

| Mechanism | Source | Live path | Semantics |
|-----------|--------|-----------|-----------|
| `dotfile` / `link` in cookbooks | `config/<name>` | `$HOME/...` | **symlink** |
| apm (`config/apm/apm.yml`) | `config/.claude/plugins/chck/plugins/personal-skills/skills/<name>/` | `~/.config/claude/skills/<name>/` | **copy** |
| mise (`config/mise/config.toml`) | tracked, symlinked | `~/.config/mise/config.toml` | symlink |
| Homebrew / cargo / `github_binary` | cookbook recipe | — | installs only |

The symlink/copy distinction is the trap:

- **Symlinked** (`config/karabiner/`, `config/AGENTS.md`, `config/.zsh/`, …) —
  editing the live path edits a tracked file. Valid, but check `git status`
  afterwards; the change is real and needs a commit.
- **Copied** (agent skills under `~/.config/claude/skills/`) — editing the live
  path is lost the next time `apm install -g` runs. Always edit
  `config/.claude/plugins/chck/plugins/personal-skills/skills/<name>/SKILL.md`,
  then redeploy. No version bump in `apm.yml` / `plugin.json` is needed.

`~/.claude/plugins/marketplaces/chck/` and `~/.claude/plugins/cache/chck/` hold
retired copies of the same skills. They are not the source; do not edit them.

## Commands

This repo has no `Makefile.toml` — the global `makers` convention does not apply.

```shell
./install.sh -n   # dry run; always do this before applying
./install.sh      # apply
apm install -g    # redeploy skills / MCP config after editing config/apm/apm.yml
```

## Files a tool owns

Do not reformat or hand-restructure these; the owning app rewrites them in its
own format, and pre-commit already excludes them:

- `config/karabiner/karabiner.json` — Karabiner-Elements
- `config/settings.json` — Zed (JSONC, so it is excluded from JSON hooks)
- `config/simplebarrc.json` — simple-bar
- `config/.zsh/lib/{aliases,apps}.zsh` — appended to by cookbooks through the
  `~/.zsh` symlink; add new entries at the tail, do not reorder

Never write `mise use --global` or `apm install -g <package>` in a cookbook.
Both rewrite a symlinked, tracked file and surface as a diff here.

## Further reading

- `.github/CONTRIBUTING.md` — install-method decision table, adding a
  mise tool / apm skill / MCP server, what may be committed, pre-commit hooks
- `/add-cookbook` skill — per-method cookbook templates and idempotency rules
- `README.md` — setup and layout

## Before committing

Run `./install.sh -n` for cookbook changes, and confirm what actually landed
(`ls ~/.config/claude/skills/`, `ls -l <live-path>`) rather than trusting an
exit code — the apm and mitamae paths both report success while deploying
nothing.
