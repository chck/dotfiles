case node[:platform]
when 'darwin'
  execute 'brew install kubernetes-helm'
else
  raise NotImplementedError
end
