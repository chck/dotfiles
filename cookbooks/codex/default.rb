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
  # ~/.codex holds Codex's own state next to its configuration, so config.toml
  # is copied in rather than symlinked. Codex writes back into whichever config
  # file it loads — plugin and marketplace entries, hook trust hashes,
  # per-project trust, TUI counters — and through a symlink all of that,
  # absolute paths included, lands in this public repository.
  #
  # The copy is made once, for a machine that has no file yet; an existing
  # ~/.codex/config.toml is left alone. A setting changed in config/codex/
  # therefore has to be applied to the live file by hand, the same drift
  # config/otty has.
  directory codex_config do
    user node[:user]
    mode '755'
  end

  codex_config_file = File.join(codex_config, 'config.toml')
  tracked_config_file = File.join(dotfiles_root, 'config/codex/config.toml')

  # A machine provisioned while this was a symlink keeps whatever state Codex
  # wrote: the link is replaced by a file holding the same content.
  execute "convert #{codex_config_file} from a symlink to a copy" do
    command %(t="$(mktemp)" && cat "#{codex_config_file}" > "$t" && mv "$t" "#{codex_config_file}" && chmod 644 "#{codex_config_file}")
    only_if "test -L \"#{codex_config_file}\" && test -e \"#{codex_config_file}\""
  end

  execute "copy config/codex/config.toml to #{codex_config_file}" do
    command %(rm -f "#{codex_config_file}" && cp "#{tracked_config_file}" "#{codex_config_file}")
    not_if "test -f \"#{codex_config_file}\" && ! test -L \"#{codex_config_file}\""
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

  # The personal skill source is also a Claude Code marketplace plugin. Codex
  # can consume the same package from a local marketplace, so the skill
  # definitions stay in one place instead of being copied into a Codex-only
  # tree. The apm deployment remains for other agents that use ~/.agents/skills.
  codex_marketplace = File.join(dotfiles_root, 'config/.claude/plugins/chck')
  execute "mise exec -- codex plugin marketplace add #{codex_marketplace}" do
    not_if {
      `mise exec -- codex plugin marketplace list --json 2>/dev/null`.include?(codex_marketplace)
    }
  end

  execute 'mise exec -- codex plugin add personal-skills@chck' do
    not_if {
      `mise exec -- codex plugin list 2>/dev/null`.include?('personal-skills@chck')
    }
  end

  # WakaTime's official Codex plugin records prompts and file-edit events while
  # reusing the standard ~/.wakatime.cfg configuration.
  execute 'mise exec -- codex plugin marketplace add wakatime/codex-cli-wakatime' do
    not_if {
      `mise exec -- codex plugin marketplace list --json 2>/dev/null`.include?('https://github.com/wakatime/codex-cli-wakatime.git')
    }
  end

  execute 'mise exec -- codex plugin add codex-cli-wakatime@wakatime' do
    not_if {
      `mise exec -- codex plugin list 2>/dev/null`.include?('codex-cli-wakatime@wakatime')
    }
  end

  # Diagram Design publishes a native Codex plugin with the same diagram
  # skills and commands as its Claude Code plugin.
  execute 'mise exec -- codex plugin marketplace add cathrynlavery/diagram-design' do
    not_if {
      `mise exec -- codex plugin marketplace list --json 2>/dev/null`.include?('https://github.com/cathrynlavery/diagram-design.git')
    }
  end

  execute 'mise exec -- codex plugin add diagram-design@diagram-design' do
    not_if {
      `mise exec -- codex plugin list 2>/dev/null`.include?('diagram-design@diagram-design')
    }
  end

  # Shared MCP servers are declared once in config/apm/apm.yml and written to
  # every agent's native config by this single run.
  #
  # It runs from here rather than from cookbooks/claude because apm creates
  # ~/.codex/config.toml when that file is missing: started earlier, it would
  # win the race against the copy above, which then finds a real file and leaves
  # Codex without approval_policy or sandbox_mode.
  #
  # Every target goes in one run. apm treats `--target` as the authoritative
  # runtime set and prunes the servers of every runtime outside it, so two runs
  # delete each other's work — claude is named for that reason, even though
  # config/apm/apm.yml already targets it. `--target a --target b` keeps only
  # the last flag, so the list has to be comma-separated.
  #
  # CODEX_HOME is pinned because Codex resolves its home from that variable, and
  # a launcher that exports its own (Orca does) otherwise takes the block while
  # ~/.codex/config.toml stays empty and apm still reports success.
  execute 'CODEX_HOME="$HOME/.codex" mise exec -- apm install -g --only mcp --target claude,gemini,codex'

  # Fails the provision when the deploy above reports success without writing
  # the block. grep, not rg: cookbooks/ripgrep is included after this recipe in
  # the darwin role, so rg does not exist yet on a fresh machine.
  execute 'verify Codex MCP configuration' do
    command 'test -f "$HOME/.codex/config.toml" && grep -q "^\\[mcp_servers\\." "$HOME/.codex/config.toml"'
  end
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
