case node[:platform]
when 'darwin'
  execute 'brew install --cask linear-linear' do
    not_if 'test -d /Applications/Linear.app/'
  end
else
  raise NotImplementedError
end
