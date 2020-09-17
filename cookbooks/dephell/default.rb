case node[:platform]
when 'darwin'
  execute 'curl -L dephell.org/install | python3' do
    not_if 'which dephell'
  end
else
  raise NotImplementedError
end
