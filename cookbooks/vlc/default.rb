case node[:platform]
when 'darwin'
  execute 'brew install --cask vlc' do
    not_if 'test -d /Applications/VLC.app/'
  end
else
  raise NotImplementedError
end
