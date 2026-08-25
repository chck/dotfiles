case node[:platform]
when 'darwin'
  execute 'brew install --cask claude' do
    not_if { File.directory?('/Applications/Claude.app') }
  end
  # settings.json is read from ~/.config/claude/ (new path since Claude Code 1.x)
  claude_settings = File.join(dotfiles_root, 'config/.claude/settings.json')
  link File.expand_path('~/.config/claude/settings.json') do
    to claude_settings
    force true
  end
  # CLAUDE.md is shared with other coding agents as AGENTS.md
  dotfile ".claude/CLAUDE.md" do
    source "AGENTS.md"
  end
  # Language-specific rules, read on demand from the main AGENTS.md
  dotfile ".claude/python/AGENTS.md" do
    source "python/AGENTS.md"
  end
  dotfile ".claude/rust/AGENTS.md" do
    source "rust/AGENTS.md"
  end
  dotfile ".claude/javascript/AGENTS.md" do
    source "javascript/AGENTS.md"
  end

  # Personal skills are declared in config/apm/apm.yml as a local path and
  # deployed by the `apm install -g` below, same as the third-party ones. They
  # used to go through the "chck" marketplace plugin, which needed a marketplace
  # registration, a plugin install, and an rsync into the plugin cache directory
  # located by `find ... | head -1` on every run.

  # WakaTime for Claude Code (https://wakatime.com/claude-code): time tracking plugin.
  # settings.json already enables "claude-code-wakatime@wakatime": true.
  # The API key lives in ~/.wakatime.cfg (secret, not managed here) — the plugin
  # prompts for it on first run, and wakatime-cli self-installs to ~/.wakatime/.
  execute 'claude plugins marketplace add https://github.com/wakatime/claude-code-wakatime.git' do
    not_if {
      f = File.expand_path('~/.config/claude/plugins/known_marketplaces.json')
      File.exist?(f) && File.read(f).include?('"wakatime"')
    }
  end

  execute 'claude plugins install claude-code-wakatime@wakatime --scope user' do
    not_if {
      f = File.expand_path('~/.config/claude/plugins/installed_plugins.json')
      File.exist?(f) && File.read(f).include?('claude-code-wakatime@wakatime')
    }
  end

  # Third-party skills (ibelick/ui-skills, anthropics/skills) are declared in
  # config/apm/apm.yml and deployed to ~/.config/claude/skills/ by apm, which is
  # installed via mise. This replaced ibelick's install.sh, whose not_if guard
  # meant upstream additions were never picked up after the first run.
  #
  # Edit config/apm/apm.yml by hand. Do NOT run `apm install -g <package>`: it
  # rewrites the symlinked manifest and shows up as a diff in this repository.
  apm_manifest = File.join(dotfiles_root, 'config/apm/apm.yml')

  execute 'mkdir -p ~/.apm' do
    not_if 'test -d ~/.apm'
  end

  link File.expand_path('~/.apm/apm.yml') do
    to apm_manifest
    user node[:user]
    force true
  end

  # Runs on every provision so newly declared skills are picked up. Goes through
  # `mise exec` because apm is a mise-managed shim and mitamae's /bin/sh does not
  # have the shim directory on PATH.
  execute 'mise exec -- apm install -g'

  # thedotmack/claude-mem: persistent memory plugin for Claude Code.
  execute 'claude plugins marketplace add https://github.com/thedotmack/claude-mem.git' do
    not_if {
      f = File.expand_path('~/.config/claude/plugins/known_marketplaces.json')
      File.exist?(f) && File.read(f).include?('"thedotmack"')
    }
  end

  execute 'claude plugins install claude-mem@thedotmack --scope user' do
    not_if {
      f = File.expand_path('~/.config/claude/plugins/installed_plugins.json')
      File.exist?(f) && File.read(f).include?('claude-mem@thedotmack')
    }
  end

  # mattpocock/skills: Matt Pocock's engineering skills (grill-me / grilling, etc.).
  # settings.json already enables "mattpocock-skills@mattpocock": true.
  execute 'claude plugins marketplace add https://github.com/mattpocock/skills.git' do
    not_if {
      f = File.expand_path('~/.config/claude/plugins/known_marketplaces.json')
      File.exist?(f) && File.read(f).include?('"mattpocock"')
    }
  end

  execute 'claude plugins install mattpocock-skills@mattpocock --scope user' do
    not_if {
      f = File.expand_path('~/.config/claude/plugins/installed_plugins.json')
      File.exist?(f) && File.read(f).include?('mattpocock-skills@mattpocock')
    }
  end

  # cathrynlavery/diagram-design: editorial HTML/SVG diagram types, plus the
  # /export-diagram, /import-drawio, /import-mermaid, /profile and /doctor
  # commands. Installed as a plugin rather than an apm skill because apm deploys
  # skills/ only and would drop those commands.
  # settings.json already enables "diagram-design@diagram-design": true.
  # PNG export additionally needs Playwright (`pip install playwright &&
  # playwright install chromium`); HTML and SVG output need nothing.
  execute 'claude plugins marketplace add https://github.com/cathrynlavery/diagram-design.git' do
    not_if {
      f = File.expand_path('~/.config/claude/plugins/known_marketplaces.json')
      File.exist?(f) && File.read(f).include?('"diagram-design"')
    }
  end

  execute 'claude plugins install diagram-design@diagram-design --scope user' do
    not_if {
      f = File.expand_path('~/.config/claude/plugins/installed_plugins.json')
      File.exist?(f) && File.read(f).include?('diagram-design@diagram-design')
    }
  end

  # MCP servers are declared in config/apm/apm.yml alongside the skills and
  # written to ~/.config/claude/.claude.json by the `apm install -g` above.
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
