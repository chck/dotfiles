case node[:platform]
when 'darwin'
  execute 'brew cask install vlc' do
    not_if 'test -d /Applications/VLC.app/'
  end
else
  raise NotImplementedError
end
