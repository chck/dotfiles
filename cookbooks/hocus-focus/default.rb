brew cask install hocus-focuscase node[:platform]
when 'darwin'
  execute 'brew cask install hocus-focus'
else
  raise NotImplementedError
end
