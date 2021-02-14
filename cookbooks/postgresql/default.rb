case node[:platform]
when 'darwin'
  execute 'brew install postgresql' do
    not_if 'which postgres'
  end
else
  raise NotImplementedError
end
