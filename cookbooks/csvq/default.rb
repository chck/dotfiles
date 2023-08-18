case node[:platform]
when 'darwin'
  execute 'brew install csvq' do
    not_if 'which csvq'
  end
else
  raise NotImplementedError
end
