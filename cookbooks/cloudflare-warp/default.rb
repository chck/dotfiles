case node[:platform]
when 'darwin'
  execute 'brew install --cask cloudflare-warp' do
    not_if 'test -d /Applications/Cloudflare\ WARP.app'
  end
else
  raise NotImplementedError
end
