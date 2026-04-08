case node[:platform]
when 'darwin'
  execute 'brew install --cask claude' do
    not_if 'test -d /Applications/Claude.app/'
  end
  dotfile ".claude/CLAUDE.md"
  dotfile ".claude/skills"
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
