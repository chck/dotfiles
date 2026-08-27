case node[:platform]
when 'darwin'
  execute 'brew install ollama' do
    not_if 'which ollama'
  end
  execute 'brew install --cask ollama-app' do
    not_if 'test -d /Applications/Ollama.app'
  end

  # Ollama.app runs its server as a child of the GUI app, so shell exports never
  # reach it. The agent seeds the launchd user session instead; see the plist for
  # what each variable does and why.
  dotfile 'Library/LaunchAgents/local.ollama.env.plist' do
    source 'ollama/local.ollama.env.plist'
  end

  execute 'launchctl bootstrap gui/$(id -u) $HOME/Library/LaunchAgents/local.ollama.env.plist' do
    not_if 'launchctl print gui/$(id -u)/local.ollama.env >/dev/null 2>&1'
  end

  # 23GB download, so it only runs when the model is absent. only_if keeps a
  # fresh machine that has not started Ollama.app yet from failing the role.
  execute 'ollama pull qwen3.6:35b-a3b-coding' do
    not_if 'ollama list | grep -q "qwen3\.6:35b-a3b-coding"'
    only_if 'curl -sf http://localhost:11434/api/tags >/dev/null'
  end
else
  raise NotImplementedError
end
