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
| apm (`config/apm/apm.yml`) | `config/.claude/plugins/chck/plugins/personal-skills/skills/<name>/` | `~/.config/claude/skills/<name>/` and `~/.agents/skills/<name>/` | **copy** |
| mise (`config/mise/config.toml`) | tracked, symlinked | `~/.config/mise/config.toml` | symlink |
| `execute` copy in `cookbooks/codex` | `config/codex/config.toml` | `~/.codex/config.toml` | **copy, once** |
| Homebrew / cargo / `github_binary` | cookbook recipe | — | installs only |
| LaunchAgent (`config/ollama/*.plist`) | tracked, symlinked | `~/Library/LaunchAgents/` | symlink + `launchctl bootstrap` |

A LaunchAgent is how a GUI app gets configuration it cannot read from the shell.
Ollama.app spawns its server as a child process, so `~/.zshrc` never reaches it;
only the launchd user session does. `launchctl bootstrap` is guarded by
`launchctl print`, and the app must be restarted before new values take effect.

The symlink/copy distinction is the trap:

- **Symlinked** (`config/karabiner/`, `config/AGENTS.md`, `config/.zsh/`, …) —
  editing the live path edits a tracked file. Valid, but check `git status`
  afterwards; the change is real and needs a commit.
- **Copied** (agent skills under `~/.config/claude/skills/` and
  `~/.agents/skills/`) — editing either live path is lost the next time
  `apm install -g` runs. Always edit
  `config/.claude/plugins/chck/plugins/personal-skills/skills/<name>/SKILL.md`,
  then redeploy. No version bump in `apm.yml` / `plugin.json` is needed.
- **Copied once** (`config/codex/config.toml`) — the copy is made only on a
  machine that has no `~/.codex/config.toml` yet. Editing the source changes
  nothing live, and editing the live file never reaches this repository, so a
  setting has to be written on both sides.

apm deploys one copy per target. Claude Code reads only
`~/.config/claude/skills/`; every other agent reads `~/.agents/skills/`, so both
copies are live and a skill edited in one place is not edited in the other.

`~/.claude/plugins/marketplaces/chck/` and `~/.claude/plugins/cache/chck/` hold
retired copies of the same skills. They are not the source; do not edit them.

## Commands

This repo has no `Makefile.toml` — the global `makers` convention does not apply.

```shell
./install.sh -n   # dry run; always do this before applying
./install.sh      # apply
apm install -g    # redeploy skills / MCP config after editing config/apm/apm.yml
```

**Apply only from the main checkout, never from a worktree.** `dotfile` / `link`
resolve their source against the repository the run starts in, so applying from
`.worktrees/<branch>` or an Orca workspace repoints every deployed symlink — the
four `AGENTS.md` links, `~/.zsh`, `config/karabiner/`, the LaunchAgents — at a
directory that is deleted when the worktree is. A dry run from a worktree is safe
and reports the repointing as a pending change; read those lines as the signal to
apply elsewhere, not as drift to fix:

```
link[/Users/…/.codex/AGENTS.md] to will change from '…/dotfiles/config/AGENTS.md'
  to '…/orca/workspaces/dotfiles/<name>/config/AGENTS.md'
```

## Role file layout

`roles/darwin/default.rb` is grouped by purpose under `# --- <section> ---`
comments, ordered by how early a tool is wanted on a fresh machine. A new
`include_cookbook` line goes in its section, not at the end of the file; reading
that one file is the whole lookup, so no cookbook carries a category comment of
its own.

Order does not express dependency. A cookbook that needs another one includes it
itself — `include_cookbook 'mas'` at the top of a Mac App Store recipe,
`include_cookbook 'rust'` in a `cargo` one, `include_cookbook 'mise'` in one that
shells out to `mise exec`. `include_recipe` is idempotent in mitamae, so the
included recipe still runs exactly once however many recipes ask for it.

`zsh` is the exception and stays first: cookbooks append to `~/.zsh/lib/*.zsh`
through the symlink it creates, and appending before that link exists writes a
real file where the link belongs.

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
- `config/codex/config.toml` — Codex. It writes its own state into whichever
  config file it loads: `[marketplaces.*]` and `[plugins.*]` entries carrying
  absolute paths, `[hooks.state.*]` trust hashes, `[projects.*]` trust levels,
  `[tui.*]` counters. That is why `cookbooks/codex` copies it instead of linking
  it; keep this file to the settings a fresh machine needs.
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
(`ls ~/.config/claude/skills/`, `ls ~/.agents/skills/`, `ls -l <live-path>`)
rather than trusting an exit code — the apm and mitamae paths both report
success while deploying nothing.
