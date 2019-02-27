case node[:platform]
when 'darwin'
  execute 'brew cask install skype' do
    not_if 'test -d /Applications/Skype.app/'
  end
else
  raise NotImplementedError
end
