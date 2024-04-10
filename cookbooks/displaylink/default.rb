case node[:platform]
when 'darwin'
  execute 'brew install --cask displaylink' do
    not_if 'test -d /Applications/DisplayLink\ Manager.app'
  end
else
  raise NotImplementedError
end
