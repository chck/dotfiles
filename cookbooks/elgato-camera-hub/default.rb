case node[:platform]
when 'darwin'
  execute 'brew install --cask elgato-camera-hub' do
    not_if 'test -d /Applications/Elgato\ Camera\ Hub.app'
  end
else
  raise NotImplementedError
end
