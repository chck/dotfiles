case node[:platform]
when 'darwin'
  execute 'brew install gnu-sed' do
    not_if 'which gsed'
  end
else
  raise NotImplementedError
end
