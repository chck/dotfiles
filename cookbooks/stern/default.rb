case node[:platform]
when 'darwin'
  execute 'brew install stern' do
    not_if 'which stern'
  end
else
  raise NotImplementedError
end
