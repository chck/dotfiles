case node[:platform]
when 'darwin'
  execute 'brew install --cask dockdoor' do
    not_if 'test -d /Applications/DockDoor.app/'
  end
else
  raise NotImplementedError
end
