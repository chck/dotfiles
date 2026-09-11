---
name: add-cookbook
description: Add a new app installation cookbook in itamae format to the dotfiles cookbooks/ directory. Use this skill whenever the user wants to install a new app, tool, or package via dotfiles, mentions adding something to cookbooks, says "dotfilesに追加", "cookbookを作る", "itamaeでインストール", or asks to track a new tool in the dotfiles repo. Also triggers when the user wants to add an alias or environment variable setup for a new tool.
---

# Add Itamae Cookbook

This dotfiles repo uses [MItamae](https://github.com/itamae-kitchen/mitamae) for provisioning.

## Repository structure

```
cookbooks/<app-name>/default.rb   ← one file per app
roles/darwin/default.rb           ← macOS role (most apps go here)
roles/base/default.rb             ← cross-platform role (rare)
```

## Steps

1. **Gather info** — if not already clear from context, ask:
   - App name (determines directory name, use kebab-case)
   - Install method — see "Choosing an install method" below
   - macOS only, Ubuntu only, or both?
   - Any post-install config: aliases, env vars, dotfiles to symlink?

2. **Create `cookbooks/<app-name>/default.rb`** following the patterns below.
   - Only create `files/` and `templates/` subdirectories if the cookbook actually uses them. Do not create them with `.keep` files just for structure.

3. **Add to role** — add `include_cookbook '<app-name>'` to the appropriate role file:
   - `roles/darwin/default.rb` — macOS-only or GUI apps
   - `roles/base/default.rb` — truly cross-platform CLI tools

   Put the line in the section it belongs to, not at the end of the file.
   `roles/darwin/default.rb` is grouped by purpose under `# --- <section> ---`
   comments (editors, AI agents, containers, CLI utilities, Mac App Store, …),
   ordered by how early the tool is wanted on a fresh machine. Reading that one
   file is the whole lookup — no cookbook needs to be opened to find the right
   place, and no cookbook carries a category comment of its own. If nothing
   fits, add a section rather than appending to an unrelated one.

4. **Declare dependencies in the cookbook, not by position.** A cookbook that
   needs another one calls `include_cookbook '<other>'` at the top of its own
   recipe. `include_recipe` is idempotent in mitamae — the included recipe runs
   once no matter how many recipes ask for it — so this costs nothing and makes
   the entry safe to move around in the role file.

   ```ruby
   case node[:platform]
   when 'darwin'
     include_cookbook 'mas'
     execute 'mas install <id>' do
   ```

   Existing dependencies to copy the shape from: `mas` (every Mac App Store
   cookbook), `rust` (anything installed with the `cargo` define), `mise`
   (anything that shells out to `mise exec`).

   `zsh` is the exception that stays positional: cookbooks append to
   `~/.zsh/lib/*.zsh` through the symlink the zsh cookbook creates, and
   appending before it exists writes a real file where the link belongs. It is
   first in the role file and depended on implicitly.

## Choosing an install method

Decide in this order:

1. Agent skill or MCP server → **apm** (no cookbook)
2. GUI application → `brew install --cask`
3. Version needs controlling (language runtime, or a tool that differs per project) → **mise**
4. Run `mise registry <name>` — if listed, → **mise**
5. Distributed only through the Mac App Store → `mas install <id>`
6. Otherwise → `brew install` (plus `apt install` if Ubuntu is in scope)
7. `cargo-*` subcommand or crate that should track the Rust toolchain → `cargo`
8. In no registry at all → `github_binary`

Build dependencies (openssl, cmake, pkg-config) always go through `brew`/`apt`,
not mise.

A Claude Code **plugin** is not an apm package: plugins ship their own runtime
(npm builds, self-installing binaries) and stay on the plugin CLI in
`cookbooks/claude`. apm carries file primitives only.

aqua is intentionally unused here — it manages no packages in this repo. Do not
add aqua-based cookbooks.

## Patterns

### agent skill or MCP server (no cookbook needed)

Add an entry to `config/apm/apm.yml`:

```yaml
dependencies:
  apm:
    - owner/repo/skills/<name>      # skill inside a repo
    - ~/absolute/path/to/package    # skill kept locally
  mcp:
    - name: <server>
      transport: stdio
      command: <cmd>
      args: [...]
```

`cookbooks/claude` symlinks that file to `~/.apm/apm.yml` and runs
`apm install -g`. Three rules:

- **Never pass a package to the CLI** (`apm install -g <pkg>`). It rewrites the
  symlinked manifest, producing a diff in this repo.
- **A local package needs its own `apm.yml`.** Without one apm resolves the path,
  reports success, and deploys nothing.
- **A local path must be absolute or `~`-expanded.** A relative path resolves
  against `~/.apm/`, not the manifest, and fails the same silent way.

The last two are not caught by `apm install --dry-run`, which reports the package
as installable either way. After editing, verify by listing
`~/.config/claude/skills/` rather than trusting the exit code.

### mise-managed tool (no cookbook needed)

Add one line to `config/mise/config.toml`:

```toml
<tool> = "latest"
```

`cookbooks/mise` symlinks that file to `~/.config/mise/config.toml` and runs
`mise install`, so no cookbook is required. Two rules:

- **Never write `mise use --global` in a cookbook.** It rewrites the symlinked
  file, producing a diff in this repo.
- **Keep `"latest"`.** The `up` alias runs `mise up --bump`, which rewrites
  pinned versions in place. Pin in `~/.config/mise/conf.d/*.toml` instead, which
  is machine-local and untracked.

Only create a cookbook when the tool needs extra steps beyond installation
(aliases, env vars, config symlinks) — see `cookbooks/pre-commit/` for that shape.

### brew CLI tool (darwin only)
```ruby
case node[:platform]
when 'darwin'
  execute 'brew install <pkg>' do
    not_if 'which <cmd>'
  end
else
  raise NotImplementedError
end
```

### brew cask GUI app (darwin only)
```ruby
case node[:platform]
when 'darwin'
  execute 'brew install --cask <pkg>' do
    not_if 'test -d /Applications/<App>.app'
  end
else
  raise NotImplementedError
end
```

### Mac App Store app (darwin only)
```ruby
case node[:platform]
when 'darwin'
  include_cookbook 'mas'
  execute 'mas install <id>' do
    not_if 'mas list | grep -qw <id>'
  end
else
  raise NotImplementedError
end
```
The id is the number in the App Store URL (`.../id1594063111`). Guard on the
`mas list` receipt rather than on `/Applications/<App>.app`: a bundle name that
carries a space or drops a version suffix is not derivable from the listing, and
a wrong path re-downloads the app on every apply.

### Cross-platform (darwin + ubuntu)
```ruby
case node[:platform]
when 'darwin'
  execute 'brew install <pkg>' do
    not_if 'which <cmd>'
  end
when 'ubuntu'
  execute 'sudo apt install -y <pkg>' do
    not_if 'which <cmd>'
  end
else
  raise NotImplementedError
end
```

### Cargo (Rust) package
```ruby
cargo '<crate-name>'
```

### GitHub binary release
```ruby
github_binary '<cmd>' do
  repository '<owner>/<repo>'
  version 'v1.2.3'
  archive '<cmd>-v1.2.3-aarch64-apple-darwin.tar.gz'
end
```

## Optional post-install blocks

### Alias
```ruby
execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# <app>
alias x="<cmd>"
EOF
''' do
  not_if 'grep <app> ~/.zsh/lib/aliases.zsh'
end
```

### Environment variable
```ruby
execute '''cat <<EOF >> ~/.zsh/lib/apps.zsh
# <app>
export <VAR>=<value>
EOF
''' do
  not_if 'grep <VAR> ~/.zsh/lib/apps.zsh'
end
```

### Symlink dotfile/config
```ruby
dotfile '.<config-file>'
```
The source is resolved from `config/` in the repo root. Make sure the file exists there first.

## This repository is public

Before adding a file to `config/`, check that it holds no secrets (API keys,
tokens, licence codes) and nothing machine-specific. Two things to watch for:

- **Secrets** — leave the file out of `config/` and let the tool's own local
  override mechanism supply them (e.g. `~/.config/mise/conf.d/*.toml`,
  `~/.zshrc.local`). Reference the mechanism in a comment instead of the value.
- **Files the owning app rewrites** — symlinking one into `config/` means the app
  edits a tracked file, producing repeated diffs. Either accept the app's own
  format as the committed baseline and exclude the file from reformatting hooks
  (see `config/karabiner/karabiner.json` in `.pre-commit-config.yaml`), or leave
  it unmanaged and `.gitignore` it.

## Idempotency rules

- CLI tool: `not_if 'which <cmd>'`
- macOS app bundle: `not_if 'test -d /Applications/<App>.app'`
- Mac App Store app: `not_if 'mas list | grep -qw <id>'`
- File existence: `not_if 'test -f <path>'`
- apt package: `not_if "dpkg -l | grep '^ii' | grep <pkg>"`
- Alias already present: `not_if 'grep <unique-string> ~/.zsh/lib/aliases.zsh'`
