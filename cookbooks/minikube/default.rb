case node[:platform]
when 'darwin'
  execute 'brew install minikube' do
    not_if 'which minikube'
  end
else
  raise NotImplementedError
end
