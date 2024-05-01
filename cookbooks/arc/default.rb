case node[:platform]
when 'darwin'
  execute 'brew install --cask arc' do
    not_if 'test -d /Applications/Arc.app/'
  end
else
  raise NotImplementedError
end
