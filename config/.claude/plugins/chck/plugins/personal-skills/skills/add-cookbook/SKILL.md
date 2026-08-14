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

3. **Add to role** — append `include_cookbook '<app-name>'` to the appropriate role file:
   - `roles/darwin/default.rb` — macOS-only or GUI apps
   - `roles/base/default.rb` — truly cross-platform CLI tools

## Choosing an install method

Decide in this order:

1. GUI application → `brew install --cask`
2. Version needs controlling (language runtime, or a tool that differs per project) → **mise**
3. Run `mise registry <name>` — if listed, → **mise**
4. Otherwise → `brew install` (plus `apt install` if Ubuntu is in scope)
5. `cargo-*` subcommand or crate that should track the Rust toolchain → `cargo`
6. In no registry at all → `github_binary`

Build dependencies (openssl, cmake, pkg-config) always go through `brew`/`apt`,
not mise.

aqua is intentionally unused here — it manages no packages in this repo. Do not
add aqua-based cookbooks.

## Patterns

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
- File existence: `not_if 'test -f <path>'`
- apt package: `not_if "dpkg -l | grep '^ii' | grep <pkg>"`
- Alias already present: `not_if 'grep <unique-string> ~/.zsh/lib/aliases.zsh'`
