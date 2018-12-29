case node[:platform]
when 'darwin'
  execute 'brew cask install google-chrome'
else
  raise NotImplementedError
end
