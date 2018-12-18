case node[:platform]
when 'darwin'
  execute 'mas install 539883307'
else
  raise NotImplementedError
end
