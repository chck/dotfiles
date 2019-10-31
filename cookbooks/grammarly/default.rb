case node[:platform]
when 'darwin'
  execute 'brew cask install grammarly' do
    not_if 'test -d /Applications/Grammarly.app/'
  end
else
  raise NotImplementedError
end
