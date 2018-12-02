case node[:platform]
when 'darwin'
  execute 'brew install swig'
else
  raise NotImplementedError
end
