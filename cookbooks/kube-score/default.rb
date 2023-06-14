case node[:platform]
when 'darwin'
  execute 'brew install kube-score' do
    not_if 'which kube-score'
  end
else
  raise NotImplementedError
end
