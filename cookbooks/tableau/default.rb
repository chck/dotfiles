case node[:platform]
when 'darwin'
  execute 'brew install --cask tableau' do
    not_if 'test -d /Applications/Tableau*.app'
  end
else
  raise NotImplementedError
end
