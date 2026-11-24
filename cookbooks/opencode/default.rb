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

# No alias here: `oc` is defined in config/.zsh/lib/aliases.zsh and points at
# this `opencode`. The Homebrew formula ships the 2.x line, so the separate
# npm-installed `opencode2` beta is no longer needed.
