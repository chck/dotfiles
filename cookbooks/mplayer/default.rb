case node[:platform]
when 'darwin'
  execute 'brew install --cask xquartz' do
    not_if 'which xquartz'
  end
  execute 'brew install mplayer' do
    not_if 'which mplayer'
    not_if 'uname -m | grep arm64'
  end
else
  raise NotImplementedError
end
