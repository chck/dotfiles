case node[:platform]
when 'darwin'
  execute 'brew cask install webstorm' do
    not_if 'test -d /Applications/WebStorm.app/'
  end
else
  raise NotImplementedError
end
