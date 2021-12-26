case node[:platform]
when 'darwin'
  execute 'brew install --cask calibre' do
    not_if 'test -d /Applications/calibre.app/'
  end
else
  raise NotImplementedError
end
