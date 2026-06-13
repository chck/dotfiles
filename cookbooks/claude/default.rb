case node[:platform]
when 'darwin'
  execute 'brew install --cask claude' do
    not_if 'test -d /Applications/Claude.app/'
  end
  dotfile ".claude/settings.json"
  dotfile ".claude/CLAUDE.md"

  # Personal skills are packaged as the "chck" marketplace plugin.
  # Claude Code does not load skills from a symlinked directory, so ~/.claude/skills
  # is not used. Instead, skills live in dotfiles as a marketplace source and are
  # registered via the plugin CLI. Two steps are required on a new machine:
  #   1. Register the marketplace (writes known_marketplaces.json)
  #   2. Install the plugin (writes installed_plugins.json + populates the cache)
  # settings.json already enables "personal-skills@chck": true.
  chck_marketplace = File.join(dotfiles_root, 'config/.claude/plugins/chck')

  execute "claude plugins marketplace add #{chck_marketplace}" do
    not_if 'claude plugins marketplace list 2>/dev/null | grep -q chck'
  end

  execute 'claude plugins install personal-skills@chck --scope user' do
    not_if 'claude plugins list 2>/dev/null | grep -q personal-skills@chck'
  end

  # ibelick/ui-skills: design-engineer skills installed to ~/.claude/skills/
  # Uses its own install.sh (not the Claude plugins system). Must run from the
  # cloned repo so the script can find local SKILL.md files as a fallback.
  execute 'git clone --depth 1 https://github.com/ibelick/ui-skills /tmp/ibelick-ui-skills && sh /tmp/ibelick-ui-skills/install.sh --all; rm -rf /tmp/ibelick-ui-skills' do
    not_if 'test -f ~/.claude/skills/baseline-ui/SKILL.md'
  end

  # Claude Code CLI MCP servers (written to ~/.config/claude/.claude.json, not symlinkable)
  execute "claude mcp add --scope user headroom uvx -- --from 'headroom-ai[all]' headroom mcp serve" do
    not_if 'claude mcp list 2>/dev/null | grep -q headroom'
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# claude
alias c="claude"
EOF
''' do
  not_if 'grep claude ~/.zsh/lib/aliases.zsh'
end

execute '''cat <<EOF >> ~/.zsh/lib/apps.zsh
# headroom
export HEADROOM_TELEMETRY=off
EOF
''' do
  not_if 'grep HEADROOM_TELEMETRY ~/.zsh/lib/apps.zsh'
end
