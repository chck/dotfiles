case node[:platform]
when 'darwin'
  execute 'brew install opencode' do
    not_if 'which opencode'
  end

  # opencode reads its user-wide config from ~/.config/opencode/, not from
  # $HOME directly, so every dotfile here needs an explicit destination.
  opencode_config = "#{ENV['HOME']}/.config/opencode"

  # Declares Ollama as a custom provider: opencode resolves built-in providers
  # through models.dev, which knows nothing about a locally pulled model, so the
  # tool_call / limit fields have to be stated or the agent loses tool use and
  # gets a default context far below what Ollama.app actually loads.
  # See cookbooks/ollama for the server side.
  dotfile 'opencode.json' do
    source 'opencode/opencode.json'
    destination opencode_config
  end

  # Shared with the other coding agents. opencode would fall back to
  # ~/.claude/CLAUDE.md on its own, but that fallback disappears the moment
  # OPENCODE_DISABLE_CLAUDE_CODE is set, so the rules are linked directly.
  dotfile 'AGENTS.md' do
    destination opencode_config
  end
  # Language-specific rules, read on demand from the main AGENTS.md
  dotfile 'python/AGENTS.md' do
    destination opencode_config
  end
  dotfile 'rust/AGENTS.md' do
    destination opencode_config
  end
  dotfile 'javascript/AGENTS.md' do
    destination opencode_config
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# opencode
alias oc="opencode"
EOF
''' do
  not_if { File.exist?(File.expand_path('~/.zsh/lib/aliases.zsh')) && File.read(File.expand_path('~/.zsh/lib/aliases.zsh')).include?('alias oc=') }
end
