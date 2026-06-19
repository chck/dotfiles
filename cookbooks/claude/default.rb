case node[:platform]
when 'darwin'
  execute 'brew install --cask claude' do
    not_if { File.directory?('/Applications/Claude.app') }
  end
  dotfile ".claude/settings.json"
  dotfile ".claude/CLAUDE.md"

  # Personal skills are packaged as the "chck" marketplace plugin.
  # Claude Code does not load skills from a symlinked directory, so ~/.claude/skills
  # is not used. Instead, skills live in dotfiles as a marketplace source and are
  # registered via the plugin CLI. Two steps are required on a new machine:
  #   1. Register the marketplace (writes known_marketplaces.json)
  #   2. Install the plugin (writes installed_plugins.json + populates the cache)
  # settings.json already enables "personal-skills@chck": true.
  chck_marketplace = File.join(dotfiles_root, 'config/.claude/plugins/chck')

  execute "claude plugins marketplace add #{chck_marketplace}" do
    not_if {
      f = File.expand_path('~/.claude/plugins/known_marketplaces.json')
      File.exist?(f) && File.read(f).include?('"chck"')
    }
  end

  execute 'claude plugins install personal-skills@chck --scope user' do
    not_if {
      f = File.expand_path('~/.claude/plugins/installed_plugins.json')
      File.exist?(f) && File.read(f).include?('personal-skills@chck')
    }
  end

  # Sync skills to cache on every provision run — `claude plugins install` is a
  # no-op when already installed, so newly added skills would otherwise be missing.
  skills_src = File.join(dotfiles_root, 'config/.claude/plugins/chck/plugins/personal-skills/skills') + '/'
  cache_skills = '$(find ~/.claude/plugins/cache/chck/personal-skills -maxdepth 2 -type d -name skills | head -1)'
  execute 'sync personal-skills skills to plugin cache' do
    command "rsync -a #{skills_src} #{cache_skills}/"
    only_if {
      Dir.glob(File.expand_path('~/.claude/plugins/cache/chck/personal-skills/**/skills')).any? { |f| File.directory?(f) }
    }
  end

  # ibelick/ui-skills: design-engineer skills installed to ~/.claude/skills/
  # Uses its own install.sh (not the Claude plugins system). Must run from the
  # cloned repo so the script can find local SKILL.md files as a fallback.
  execute 'git clone --depth 1 https://github.com/ibelick/ui-skills /tmp/ibelick-ui-skills && mkdir -p ~/.claude/skills && sh /tmp/ibelick-ui-skills/install.sh --all; rm -rf /tmp/ibelick-ui-skills' do
    not_if { File.exist?(File.expand_path('~/.claude/skills/baseline-ui/SKILL.md')) }
  end

  # Claude Code CLI MCP servers (written to ~/.config/claude/.claude.json, not symlinkable)
  execute "claude mcp add --scope user headroom uvx -- --from 'headroom-ai[all]' headroom mcp serve" do
    not_if {
      f = File.expand_path('~/.config/claude/.claude.json')
      File.exist?(f) && File.read(f).include?('"headroom"')
    }
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# claude
alias c="claude"
EOF
''' do
  not_if { File.exist?(File.expand_path('~/.zsh/lib/aliases.zsh')) && File.read(File.expand_path('~/.zsh/lib/aliases.zsh')).include?('claude') }
end

execute '''cat <<EOF >> ~/.zsh/lib/apps.zsh
# headroom
export HEADROOM_TELEMETRY=off
EOF
''' do
  not_if { File.exist?(File.expand_path('~/.zsh/lib/apps.zsh')) && File.read(File.expand_path('~/.zsh/lib/apps.zsh')).include?('HEADROOM_TELEMETRY') }
end
