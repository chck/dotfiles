case node[:platform]
when 'darwin'
  execute 'brew install --cask yubico-yubikey-manager' do
    not_if 'test -d /Applications/YubiKey\ Manager.app/'
  end
else
  raise NotImplementedError
end
