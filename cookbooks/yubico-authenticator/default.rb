case node[:platform]
when 'darwin'
  execute 'brew install --cask yubico-authenticator' do
    not_if 'test -d /Applications/Yubico\ Authenticator.app/'
  end
else
  raise NotImplementedError
end
