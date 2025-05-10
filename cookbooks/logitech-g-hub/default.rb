case node[:platform]
when 'darwin'
  execute 'brew install --cask logitech-g-hub' do
    not_if 'test -d /Applications/lghub.app'
  end
else
  raise NotImplementedError
end
