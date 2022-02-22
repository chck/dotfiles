case node[:platform]
when 'darwin'
  execute 'brew install --cask gyazo' do
    not_if 'test -d /Applications/Gyazo.app/'
  end
else
  raise NotImplementedError
end
