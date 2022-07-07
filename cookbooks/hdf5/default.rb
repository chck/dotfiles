case node[:platform]
when 'darwin'
  execute 'brew install hdf5' do
    not_if 'which hdf5'
  end
else
  raise NotImplementedError
end
