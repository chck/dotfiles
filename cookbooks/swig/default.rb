case node[:platform]
when 'darwin'
  execute 'brew install swig' do
    not_if 'which swig'
  end
else
  raise NotImplementedError
end
