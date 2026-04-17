case node[:platform]
when 'darwin'
  execute 'brew install --cask puremac' do
    not_if 'test -d /Applications/PureMac.app/'
  end
else
  raise NotImplementedError
end
