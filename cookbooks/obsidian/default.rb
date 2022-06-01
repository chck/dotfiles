case node[:platform]
when 'darwin'
  execute 'brew install --cask obsidian' do
    not_if 'test -d /Applications/Obsidian.app/'
  end
else
  raise NotImplementedError
end
