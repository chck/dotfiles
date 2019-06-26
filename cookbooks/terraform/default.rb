case node[:platform]
when 'darwin'
  execute 'brew install terraform' do
    not_if 'which terraform'
  end
else
  raise NotImplementedError
end
