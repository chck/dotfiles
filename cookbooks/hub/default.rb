case node[:platform]
when 'darwin'
  execute 'brew install hub'
else
  raise NotImplementedError
end
