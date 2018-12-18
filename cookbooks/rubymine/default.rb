case node[:platform]
when 'darwin'
  execute 'brew cask install rubymine'
else
  raise NotImplementedError
end

dotfile '.gemrc'
