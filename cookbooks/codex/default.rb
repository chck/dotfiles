case node[:platform]
when 'darwin'
  include_cookbook 'mise'
  # The ~/.apm/apm.yml symlink the MCP step below reads is created by
  # cookbooks/claude, so this recipe pulls it in rather than relying on the
  # order of the darwin role.
  include_cookbook 'claude'
  execute 'brew install --cask chatgpt' do
    not_if 'test -d /Applications/ChatGPT.app/'
  end
  # The CLI is declared as npm:@openai/codex in config/mise/config.toml. The
  # backend is spelled out there because a bare `codex` entry resolves through
  # mise's aqua backend, which tracks a separate alpha release stream.

  # Codex reads its user-wide files from ~/.codex (or $CODEX_HOME), and its
  # global instructions file is AGENTS.md there — the same file every other
  # agent here gets.
  codex_config = "#{ENV['HOME']}/.codex"
  dotfile 'AGENTS.md' do
    destination codex_config
  end
  # Language-specific rules, read on demand from the main AGENTS.md. Codex has
  # no import directive: discovery is positional (the global file, then one per
  # directory from project root down to cwd), so these are reached only because
  # AGENTS.md tells the agent to open them.
  dotfile 'python/AGENTS.md' do
    destination codex_config
  end
  dotfile 'rust/AGENTS.md' do
    destination codex_config
  end
  dotfile 'javascript/AGENTS.md' do
    destination codex_config
  end

  # MCP servers are declared once in config/apm/apm.yml. Same split as
  # cookbooks/gemini: codex is deliberately not a target in that manifest,
  # because a full target would also copy every declared skill into ~/.codex/,
  # which Codex does not read. `--only mcp --target codex` writes just the
  # [mcp_servers.<name>] tables, into ~/.codex/config.toml.
  #
  # Runs on every provision, like the `apm install -g` it follows; apm reports
  # an already-present server as "already configured" and changes nothing.
  execute 'mise exec -- apm install -g --only mcp --target codex'
else
  raise NotImplementedError
end
