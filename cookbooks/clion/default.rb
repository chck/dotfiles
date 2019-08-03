case node[:platform]
when 'darwin'
  execute 'brew cask install clion' do
    not_if 'test -d /Applications/CLion.app/'
  end
else
  raise NotImplementedError
end
