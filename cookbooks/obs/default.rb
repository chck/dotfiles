case node[:platform]
when 'darwin'
  execute 'brew install --cask obs' do
    not_if 'test -d /Applications/OBS.app/'
  end
else
  raise NotImplementedError
end
