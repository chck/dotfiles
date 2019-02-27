case node[:platform]
when 'darwin'
  execute 'pip install yq' do
    not_if 'which yq'
  end
else
  raise NotImplementedError
end
