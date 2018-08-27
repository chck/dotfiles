case node[:platform]
when 'darwin'
  execute 'brew cask install google-japanese-ime'
else
  raise NotImplementedError
end
