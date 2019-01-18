case node[:platform]
when 'darwin'
  execute 'brew install mpv'
else
  raise NotImplementedError
end
