case node[:platform]
when 'darwin'
  version = 16
  execute "brew install postgresql@#{version}" do
    not_if 'which psql'
  end
else
  raise NotImplementedError
end
