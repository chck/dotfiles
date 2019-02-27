case node[:platform]
when 'darwin'
  execute 'brew cask install iterm2' do
    not_if 'test -d /Applications/iTerm.app/'
  end
else
  raise NotImplementedError
end
