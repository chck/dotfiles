case node[:platform]
when 'darwin'
  execute 'brew cask install calibre' do
    not_if 'test -d /Applications/calibre.app/'
  end
else
  raise NotImplementedError
end
