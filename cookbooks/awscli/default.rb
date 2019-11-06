case node[:platform]
when 'darwin'
  execute 'pip3 install awscli' do
    not_if 'which aws'
  end
else
  raise NotImplementedError
end
