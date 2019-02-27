case node[:platform]
when 'darwin'
  execute 'brew cask install hocus-focus' do
    not_if 'test -d /Applications/Hocus\ Focus.app/'
  end
else
  raise NotImplementedError
end
