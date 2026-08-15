# dotfiles
> Accio, My Utensils!

## Usage
### Clone this repository
```shell
git clone --recursive https://github.com/chck/dotfiles.git
```

### Dry-run
```shell
./install.sh -n
```

### Apply
```shell
./install.sh
```

### Add new cookbook
```shell
mkdir cookbooks/:app_name
$EDITOR cookbooks/:app_name/default.rb
$EDITOR roles/$(uname)/default.rb
```

> If you're using an AI agent (e.g. Claude Code), you can use the [`/add-cookbook`](config/.claude/plugins/chck/plugins/personal-skills/skills/add-cookbook/SKILL.md) skill instead.

See [CONTRIBUTING.md](.github/CONTRIBUTING.md) for how to pick between apm, brew,
mise and the other install methods, and for what may be committed to this public
repo.

### Add a mise-managed tool

Add one line to [`config/mise/config.toml`](config/mise/config.toml) — no cookbook
needed. Machine-local tools belong in `~/.config/mise/conf.d/*.toml`, which mise
reads alongside it and this repo does not manage.

### Add an agent skill or MCP server

Add an entry to [`config/apm/apm.yml`](config/apm/apm.yml) — no cookbook needed.
`apm install -g` deploys skills to `~/.config/claude/skills/` and MCP servers to
Claude Code's config. Claude Code plugins are not managed there; they ship their
own runtime and stay in [`cookbooks/claude`](cookbooks/claude/default.rb).
