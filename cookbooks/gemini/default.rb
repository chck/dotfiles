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

  # MCP servers are declared once in config/apm/apm.yml. `apm install -g` in
  # cookbooks/claude only configures the targets listed there (claude,
  # agent-skills), and gemini is deliberately not one of them: as a full apm
  # target it would also copy every declared skill into ~/.gemini/, which the
  # Gemini CLI does not read. `--only mcp --target gemini` writes just the
  # server block, into ~/.gemini/settings.json.
  #
  # Runs on every provision, like the `apm install -g` it follows; apm reports
  # an already-present server as "already configured" and changes nothing.
  # Depends on the ~/.apm/apm.yml symlink, which cookbooks/claude creates
  # earlier in the darwin role.
  execute 'mise exec -- apm install -g --only mcp --target gemini'
else
  raise NotImplementedError
end
