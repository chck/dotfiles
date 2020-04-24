case node[:platform]
when 'darwin'
  execute 'brew cask install inkscape' do
    not_if 'test -d /Applications/Inkscape.app/'
  end
else
  raise NotImplementedError
end
