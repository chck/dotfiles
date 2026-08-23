# Agent Instructions

Repository-local rules for this dotfiles repo. These override the global
instructions deployed from `config/AGENTS.md`.

`CLAUDE.md` is a symlink to this file: Claude Code does not discover a
project-root `AGENTS.md`, while other agents read only that name.

## What this repo is

`./install.sh` provisions a whole machine from scratch: one mitamae run over
every cookbook in the platform role, into a public repository. Two invariants
follow.

**Idempotent at OS scope.** Every apply re-runs every recipe, so one that works
the first time but duplicates or fails the second takes the whole role down with
it, not just its own cookbook. Guard installs with `not_if` / `only_if`, guard
appends with a `grep` for a unique string, and never `sed -i` a tracked file
unconditionally. Check with `./install.sh -n`, and make sure a second apply
changes nothing. A few `execute` blocks deliberately run every time
(`apm install -g`, `mise install`); they are safe only because those commands are
themselves idempotent, so keep any new unguarded command in that class.

**Public.** Before committing, read the diff for anything that should not be
published — not only credentials, but anything that identifies this machine or
its owner beyond what already is: tokens and API keys, licence codes, internal
hostnames and URLs, MAC or Bluetooth device addresses, hardware serials, other
users' absolute paths. Machine-specific values belong in the local override each
tool already has (`~/.config/mise/conf.d/*.toml`, `~/.zshrc.local`,
`~/.wakatime.cfg`), referenced by a comment rather than by value. `detect-private-key`
is the only secret-related hook and it matches PEM blocks only — it is not a
scanner, so this check is yours.

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
- `config/otty/config.toml` — Otty. It saves by replacing the file, which
  destroys the symlink, so the live copy drifts. Re-import from
  `~/.config/otty/config.toml` and recreate the link rather than editing here.
  Otty also repeats `open-with-app` per entry, which is not valid TOML.
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
