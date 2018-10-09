case node[:platform]
when 'darwin'
  execute 'brew install kustomize'
else
  raise NotImplementedError
end
