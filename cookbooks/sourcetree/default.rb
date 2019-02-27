case node[:platform]
when 'darwin'
  execute 'brew cask install sourcetree' do
    not_if 'test -d /Applications/Sourcetree.app/'
  end
else
  raise NotImplementedError
end
