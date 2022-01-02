case node[:platform]
when 'darwin'
  execute 'brew install --cask fork' do
    not_if 'test -d /Applications/Fork.app/'
  end
else
  raise NotImplementedError
end
