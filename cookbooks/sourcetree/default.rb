case node[:platform]
when 'darwin'
  execute 'brew cask install sourcetree'
else
  raise NotImplementedError
end
