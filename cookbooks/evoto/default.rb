case node[:platform]
when 'darwin'
  include_cookbook 'ax'
  # Evoto has no Homebrew cask. Bump the version from https://www.evoto.ai/ja/download.
  version = '8.1.0-362'
  url = "https://res.evoto.ai/package/#{version}/Evoto-#{version}_arm64.dmg"
  execute 'install Evoto' do
    command <<~SH
      set -e
      work=$(mktemp -d)
      trap 'hdiutil detach "$work/mnt" -quiet 2>/dev/null || true; rm -rf "$work"' EXIT
      ax #{url} -f -o "$work/Evoto.dmg" --max-bytes 4000000000 -m 1800
      hdiutil attach -nobrowse -readonly -mountpoint "$work/mnt" "$work/Evoto.dmg"
      cp -R "$work/mnt/Evoto.app" /Applications/
    SH
    not_if 'test -d /Applications/Evoto.app'
  end
else
  raise NotImplementedError
end
