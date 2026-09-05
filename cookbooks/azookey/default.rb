case node[:platform]
when 'darwin'
  execute 'brew install --cask azookey' do
    not_if 'test -d "/Library/Input Methods/azooKeyMac.app"'
  end
else
  raise NotImplementedError
end
