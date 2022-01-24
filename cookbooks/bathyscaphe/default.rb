case node[:platform]
when 'darwin'
  execute 'brew install --cask bathyscaphe' do
    not_if 'test -d /Applications/Bathyscaphe.app/'
  end
else
  raise NotImplementedError
end
