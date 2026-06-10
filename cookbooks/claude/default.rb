case node[:platform]
when 'darwin'
  execute 'brew install --cask claude' do
    not_if 'test -d /Applications/Claude.app/'
  end
  dotfile ".claude/settings.json"
  dotfile ".claude/CLAUDE.md"
  dotfile ".claude/skills"
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
