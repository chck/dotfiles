case node[:platform]
when 'darwin'
  execute 'brew install hub' do
    not_if 'which hub'
  end
else
  raise NotImplementedError
end
