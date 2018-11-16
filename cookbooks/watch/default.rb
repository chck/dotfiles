case node[:platform]
when 'darwin'
  execute 'brew install watch'
else
  raise NotImplementedError
end
