case node[:platform]
when 'darwin'
  execute 'brew install tree' do
    not_if 'which tree'
  end
else
  raise NotImplementedError
end
