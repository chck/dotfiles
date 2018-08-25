case node[:platform]
when 'darwin'
  execute 'brew cask install iterm2'
else
  raise NotImplementedError
end
