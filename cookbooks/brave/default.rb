case node[:platform]
when 'darwin'
  execute 'brew cask install brave'
else
  raise NotImplementedError
end
