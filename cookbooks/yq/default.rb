case node[:platform]
when 'darwin'
  execute 'pip install yq'
else
  raise NotImplementedError
end
