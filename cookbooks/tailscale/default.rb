case node[:platform]
when 'darwin'
  # tailscale-app is the standalone build; the pkg also installs
  # /usr/local/bin/tailscale, so no separate CLI cookbook is needed.
  execute 'brew install --cask tailscale-app' do
    not_if 'test -d /Applications/Tailscale.app'
  end
else
  raise NotImplementedError
end
