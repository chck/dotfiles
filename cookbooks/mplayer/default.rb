case node[:platform]
when 'darwin'
  execute 'brew cask install xquartz' do
    not_if 'brew cask list | grep xquartz'
  end
  execute 'brew install mplayer' do
    not_if 'which mplayer'
  end
else
  raise NotImplementedError
end
