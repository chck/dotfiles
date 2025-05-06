case node[:platform]
when 'darwin'
  execute 'brew install --cask logitech-g-hub' do
    not_if 'test -d /Applications/Logitech\ G\ HUB.app'
  end
else
  raise NotImplementedError
end
