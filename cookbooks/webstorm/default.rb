case node[:platform]
when 'darwin'
  execute 'brew cask install webstorm'
else
  raise NotImplementedError
end
