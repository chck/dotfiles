case node[:platform]
when 'darwin'
  execute 'brew install --cask raycast' do
    not_if 'test -d /Applications/Raycast.app/'
  end
else
  raise NotImplementedError
end
