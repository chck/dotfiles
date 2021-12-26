case node[:platform]
when 'darwin'
  execute 'brew install --cask clion' do
    not_if 'test -d /Applications/CLion.app/'
  end
else
  raise NotImplementedError
end
