case node[:platform]
when 'darwin'
  include_cookbook 'mise'
  include_cookbook 'ollama'

  # The CLI is declared as npm:@qwen-code/qwen-code in config/mise/config.toml
  # and installed by `mise install` in cookbooks/mise.

  # Qwen Code writes its own state (auth choice, trusted folders) into
  # ~/.qwen/settings.json, so the file is merged, not linked: the keys tracked in
  # config/qwen/settings.json are applied and everything else stays live-only.
  # The sync script is shared with cookbooks/claude; it only knows JSON objects.
  #
  # The values come from a week of measured trials: the shipped defaults (65K
  # context, 8K max_tokens, thinking on) make long tool calls truncate, which
  # reads as an endless rewrite loop. Context stays at 131072 to match what
  # Ollama.app loads (see config/ollama/local.ollama.env.plist).
  qwen_settings = File.join(dotfiles_root, 'config/qwen/settings.json')
  qwen_settings_live = File.expand_path('~/.qwen/settings.json')
  settings_sync = File.join(dotfiles_root, 'cookbooks/claude/settings-sync/sync_settings.py')
  settings_sync_command = %(python3 "#{settings_sync}" "#{qwen_settings}" "#{qwen_settings_live}")
  execute 'sync managed Qwen Code settings' do
    command settings_sync_command
    not_if "#{settings_sync_command} --check"
  end

  qwen_home = File.expand_path('~/.qwen')
  # Rules specific to the local model
  dotfile 'QWEN.md' do
    source 'qwen/QWEN.md'
    destination qwen_home
  end
  # Shared with the other coding agents
  dotfile 'AGENTS.md' do
    destination qwen_home
  end
  dotfile 'python/AGENTS.md' do
    destination qwen_home
  end
  dotfile 'rust/AGENTS.md' do
    destination qwen_home
  end
  dotfile 'javascript/AGENTS.md' do
    destination qwen_home
  end
else
  raise NotImplementedError
end
