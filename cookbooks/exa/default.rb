case node[:platform]
when 'darwin'
  execute 'brew install exa' do
    not_if 'which exa'
  end
else
  raise NotImplementedError
end
