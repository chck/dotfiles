case node[:platform]
when 'darwin'
  include_cookbook 'mise'
  execute 'brew install --cask antigravity' do
    not_if 'test -d /Applications/Antigravity.app/'
  end
  execute 'brew install --cask google-gemini' do
    not_if 'test -d /Applications/Gemini.app/'
  end
  # The CLI is declared as gemini in config/mise/config.toml, which resolves it
  # through mise's npm backend. brew's gemini-cli formula is deprecated upstream
  # and its replacement cask, antigravity-cli, ships the separate `agy` binary.
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
  # ~/.gemini/settings.json by cookbooks/claude, which runs the deploy for
  # gemini and codex together. Splitting it per cookbook does not work: each
  # `--target` run prunes the runtimes outside its own target list, so the
  # second run would empty what the first wrote.
else
  raise NotImplementedError
end
