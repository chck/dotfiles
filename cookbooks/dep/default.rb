case node[:platform]
when 'darwin'
  execute 'brew install dep'
else
  raise NotImplementedError
end
