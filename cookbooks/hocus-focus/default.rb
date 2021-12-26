case node[:platform]
when 'darwin'
  execute 'brew install --cask hocus-focus' do
    not_if 'test -d /Applications/Hocus\ Focus.app/'
  end
else
  raise NotImplementedError
end
