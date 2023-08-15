case node[:platform]
when 'darwin'
  execute 'brew install telnet' do
    not_if 'which telnet'
  end
else
  raise NotImplementedError
end
