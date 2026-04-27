case node[:platform]
when 'darwin'
  execute 'brew install gemini-cli' do
    not_if 'which gemini'
  end
  execute 'brew install --cask google-gemini' do
    not_if 'test -d /Applications/Gemini.app/'
  end
  dotfile "AGENTS.md" do
    destination "#{ENV['HOME']}/.gemini"
  end
else
  raise NotImplementedError
end
