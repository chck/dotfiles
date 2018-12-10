case node[:platform]
when 'darwin'
  execute 'brew install stern'
else
  raise NotImplementedError
end
