case node[:platform]
when 'darwin'
  execute 'brew install graphviz'
when 'ubuntu'
  execute 'apt-get install graphviz'
else
  raise NotImplementedError
end
