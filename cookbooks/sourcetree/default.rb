case node[:platform]
when 'darwin'
  execute 'brew install --cask sourcetree' do
    not_if 'test -d /Applications/Sourcetree.app/'
  end
else
  raise NotImplementedError
end
