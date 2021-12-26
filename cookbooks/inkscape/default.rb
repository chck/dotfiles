case node[:platform]
when 'darwin'
  execute 'brew install --cask inkscape' do
    not_if 'test -d /Applications/Inkscape.app/'
  end
else
  raise NotImplementedError
end
