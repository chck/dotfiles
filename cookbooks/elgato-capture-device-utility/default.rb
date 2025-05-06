case node[:platform]
when 'darwin'
  execute 'brew install --cask elgato-capture-device-utility' do
    not_if 'test -d /Applications/Elgato\ Capture\ Device\ Utility.app'
  end
else
  raise NotImplementedError
end
