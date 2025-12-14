case node[:platform]
when 'darwin'
  execute 'brew install actionlint' do
    not_if 'which actionlint'
  end
else
  raise NotImplementedError
end
