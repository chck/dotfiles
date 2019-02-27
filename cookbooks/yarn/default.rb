case node[:platform]
when 'darwin'
  execute 'brew install yarn --without-node' do
    not_if 'which yarn'
  end
else
  raise NotImplementedError
end
