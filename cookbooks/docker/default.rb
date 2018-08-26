case node[:platform]
when 'darwin'
  execute 'brew cask install docker'
else
  raise NotImplementedError
end
