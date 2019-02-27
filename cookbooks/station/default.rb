case node[:platform]
when 'darwin'
  execute 'brew cask install station' do
    not_if 'test -d /Applications/Station.app/'
  end
else
  raise NotImplementedError
end
