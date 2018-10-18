case node[:platform]
when 'darwin'
  execute 'brew install youtube-dl'
else
  raise NotImplementedError
end
