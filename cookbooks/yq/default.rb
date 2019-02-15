case node[:platform]
when 'darwin'
  execute 'brew install yq'
else
  raise NotImplementedError
end
