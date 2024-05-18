case node[:platform]
when 'darwin'
  execute 'brew install kubeconform' do
    not_if 'which kubeconform'
  end
else
  raise NotImplementedError
end
