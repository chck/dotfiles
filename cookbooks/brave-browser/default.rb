case node[:platform]
when 'darwin'
  execute 'brew cask install brave-browser'
else
  raise NotImplementedError
end
