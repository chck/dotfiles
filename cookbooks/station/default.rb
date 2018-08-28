case node[:platform]
when 'darwin'
  execute 'brew cask install station'
else
  raise NotImplementedError
end
