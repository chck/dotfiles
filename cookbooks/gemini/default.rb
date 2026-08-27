case node[:platform]
when 'darwin'
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
else
  raise NotImplementedError
end
