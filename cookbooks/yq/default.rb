case node[:platform]
when 'darwin'
  execute 'pip3 install yq' do
    not_if 'which yq'
  end
else
  raise NotImplementedError
end
