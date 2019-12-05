case node[:platform]
when 'darwin'
  execute 'brew cask install kindle' do
    not_if 'test -d /Applications/Kindle.app/'
  end
else
  raise NotImplementedError
end
