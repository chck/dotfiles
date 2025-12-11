case node[:platform]
when 'darwin'
  execute 'brew install ollama' do
    not_if 'which ollama'
  end
  execute 'brew install --cask ollama-app' do
    not_if 'test -d /Applications/Ollama.app'
  end
else
  raise NotImplementedError
end
