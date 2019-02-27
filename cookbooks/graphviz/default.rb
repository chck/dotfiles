case node[:platform]
when 'darwin'
  execute 'brew install graphviz' do
    not_if 'which dot'
  end
when 'ubuntu'
  execute 'apt-get install graphviz' do
    not_if 'which dot'
  end
else
  raise NotImplementedError
end
