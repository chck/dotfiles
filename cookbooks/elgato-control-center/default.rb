case node[:platform]
when 'darwin'
  execute 'brew install --cask elgato-control-center' do
    not_if 'test -d /Applications/Elgato\ Control\ Center.app'
  end
else
  raise NotImplementedError
end
