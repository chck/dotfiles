case node[:platform]
when 'darwin'
  execute 'brew install mkcert' do
    not_if 'which mkcert'
  end
else
  raise NotImplementedError
end
