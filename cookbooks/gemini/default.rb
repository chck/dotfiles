case node[:platform]
when 'darwin'
  execute 'brew install --cask antigravity' do
    not_if 'test -d /Applications/Antigravity.app/'
  end
  execute 'brew install --cask google-gemini' do
    not_if 'test -d /Applications/Gemini.app/'
  end
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
else
  raise NotImplementedError
end
