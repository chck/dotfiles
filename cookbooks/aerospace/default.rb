case node[:platform]
when 'darwin'
  execute 'brew tap nikitabobko/tap' do
    not_if 'brew tap | grep -q nikitabobko/tap'
  end
  execute 'brew install --cask nikitabobko/tap/aerospace' do
    not_if 'test -d /Applications/AeroSpace.app/'
  end
  dotfile '.aerospace.toml' do
    source 'aerospace.toml'
  end
else
  raise NotImplementedError
end
