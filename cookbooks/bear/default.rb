case node[:platform]
when 'darwin'
  execute 'mas install 1091189122'
else
  raise NotImplementedError
end
