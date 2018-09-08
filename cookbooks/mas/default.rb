case node[:platform]
when 'darwin'
  execute 'brew install mas'
else
  raise NotImplementedError
end
