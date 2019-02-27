case node[:platform]
when 'darwin'
  execute 'brew install kubernetes-helm' do
    not_if 'which helm'
  end
else
  raise NotImplementedError
end
