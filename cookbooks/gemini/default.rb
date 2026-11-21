case node[:platform]
when 'darwin'
  include_cookbook 'mise'
  execute 'brew install --cask antigravity' do
    not_if 'test -d /Applications/Antigravity.app/'
  end
  execute 'brew install --cask google-gemini' do
    not_if 'test -d /Applications/Gemini.app/'
  end
  # The CLI is declared as agy in config/mise/config.toml (Antigravity CLI,
  # via mise's aqua backend). Gemini CLI is retired upstream and brew's
  # gemini-cli formula is deprecated, so neither is installed.
  dotfile "AGENTS.md" do
    destination "#{ENV['HOME']}/.gemini"
  end
  # Language-specific rules, read on demand from the main AGENTS.md
  dotfile "python/AGENTS.md" do
    destination "#{ENV['HOME']}/.gemini"
  end
  dotfile "rust/AGENTS.md" do
    destination "#{ENV['HOME']}/.gemini"
  end

  # MCP servers are declared once in config/apm/apm.yml and written to
  # ~/.gemini/config/mcp_config.json (Antigravity CLI) by cookbooks/codex, which
  # runs the deploy for claude, agy and codex together. Splitting it per
  # cookbook does not work: each `--target` run prunes the runtimes outside its
  # own target list, so the second run would empty what the first wrote.
else
  raise NotImplementedError
end
