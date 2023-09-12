case node[:platform]
when 'darwin'
  execute 'brew install grpcurl' do
    not_if 'which grpcurl'
  end
else
  raise NotImplementedError
end
