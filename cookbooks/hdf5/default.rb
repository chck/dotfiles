case node[:platform]
when 'darwin'
  execute 'brew install hdf5' do
    not_if 'brew --prefix hdf5'
  end
else
  raise NotImplementedError
end
