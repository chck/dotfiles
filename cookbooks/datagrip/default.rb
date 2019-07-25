case node[:platform]
when 'darwin'
  execute 'brew cask install datagrip' do
    not_if 'test -d /Applications/DataGrip.app/'
  end
else
  raise NotImplementedError
end
