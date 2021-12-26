case node[:platform]
when 'darwin'
  execute 'brew install --cask datagrip' do
    not_if 'test -d /Applications/DataGrip.app/'
  end
else
  raise NotImplementedError
end
