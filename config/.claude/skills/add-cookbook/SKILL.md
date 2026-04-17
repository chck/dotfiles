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
   - Install method: `brew` CLI tool, `brew --cask` GUI app, `apt`, `cargo`, `github_binary`, or custom script
   - macOS only, Ubuntu only, or both?
   - Any post-install config: aliases, env vars, dotfiles to symlink?

2. **Create `cookbooks/<app-name>/default.rb`** following the patterns below.

3. **Add to role** — append `include_cookbook '<app-name>'` to the appropriate role file:
   - `roles/darwin/default.rb` — macOS-only or GUI apps
   - `roles/base/default.rb` — truly cross-platform CLI tools

## Patterns

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

## Idempotency rules

- CLI tool: `not_if 'which <cmd>'`
- macOS app bundle: `not_if 'test -d /Applications/<App>.app'`
- File existence: `not_if 'test -f <path>'`
- apt package: `not_if "dpkg -l | grep '^ii' | grep <pkg>"`
- Alias already present: `not_if 'grep <unique-string> ~/.zsh/lib/aliases.zsh'`
