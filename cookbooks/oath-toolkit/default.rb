case node[:platform]
when 'darwin'
  execute 'brew install oath-toolkit' do
    not_if 'which oathtool'
  end
else
  raise NotImplementedError
end
