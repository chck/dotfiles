case node[:platform]
when 'darwin'
  execute 'brew install pipenv'
else
  raise NotImplementedError
end