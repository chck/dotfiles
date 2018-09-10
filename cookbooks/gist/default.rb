case node[:platform]
when 'darwin'
  execute 'brew install gist'
else
  raise NotImplementedError
end
