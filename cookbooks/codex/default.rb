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
  # ~/.codex holds Codex's own state next to its configuration, so the two
  # tracked files below are copied in rather than symlinked. Codex writes back
  # into whichever config file it loads — plugin and marketplace entries, hook
  # trust hashes, per-project trust, TUI counters — and through a symlink all of
  # that, absolute paths included, lands in this public repository.
  #
  # The copy is made once, for a machine that has no file yet; an existing
  # ~/.codex/<name> is left alone. A setting changed in config/codex/ therefore
  # has to be applied to the live file by hand, the same drift config/otty has.
  directory codex_config do
    user node[:user]
    mode '755'
  end

  {
    'config.toml' => 'config/codex/config.toml',
    'full_auto.config.toml' => 'config/codex/full_auto.config.toml',
  }.each do |name, source|
    live = File.join(codex_config, name)
    tracked = File.join(dotfiles_root, source)

    # A machine provisioned while these were symlinks keeps whatever state Codex
    # wrote: the link is replaced by a file holding the same content.
    execute "convert #{live} from a symlink to a copy" do
      command %(t="$(mktemp)" && cat "#{live}" > "$t" && mv "$t" "#{live}" && chmod 644 "#{live}")
      only_if "test -L \"#{live}\" && test -e \"#{live}\""
    end

    execute "copy #{source} to #{live}" do
      command %(rm -f "#{live}" && cp "#{tracked}" "#{live}")
      not_if "test -f \"#{live}\" && ! test -L \"#{live}\""
    end
  end

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

  # MCP servers are declared once in config/apm/apm.yml and written to
  # ~/.codex/config.toml ([mcp_servers.<name>] tables) by cookbooks/claude,
  # which runs the deploy for gemini and codex together — one run, because each
  # `--target` run prunes the runtimes outside its own target list.
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# codex
alias x="codex"
EOF
''' do
  not_if { File.exist?(File.expand_path('~/.zsh/lib/aliases.zsh')) && File.read(File.expand_path('~/.zsh/lib/aliases.zsh')).include?('alias x="codex"') }
end
