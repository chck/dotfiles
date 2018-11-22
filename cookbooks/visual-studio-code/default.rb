case node[:platform]
when 'darwin'
  execute 'brew cask install visual-studio-code'
else
  raise NotImplementedError
end
