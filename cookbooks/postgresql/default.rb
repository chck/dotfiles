case node[:platform]
when 'darwin'
  version = 15
  execute "brew install postgresql@#{version}" do
    not_if 'which postgres'
  end
else
  raise NotImplementedError
end
