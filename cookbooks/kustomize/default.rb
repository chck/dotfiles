case node[:platform]
when 'darwin'
  execute 'brew install kustomize' do
    not_if 'which kustomize'
  end
else
  raise NotImplementedError
end
