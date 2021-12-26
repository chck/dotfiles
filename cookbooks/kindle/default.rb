case node[:platform]
when 'darwin'
  execute 'brew install --cask kindle' do
    not_if 'test -d /Applications/Kindle.app/'
  end
else
  raise NotImplementedError
end
