case node[:platform]
when 'darwin'
  execute 'brew install dep' do
    not_if 'which dep'
  end
else
  raise NotImplementedError
end
