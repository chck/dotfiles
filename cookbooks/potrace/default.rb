case node[:platform]
when 'darwin'
  execute 'brew install potrace' do
    not_if 'which potrace'
  end
else
  raise NotImplementedError
end
