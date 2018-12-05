case node[:platform]
when 'darwin'
  execute 'brew cask install skype'
else
  raise NotImplementedError
end
