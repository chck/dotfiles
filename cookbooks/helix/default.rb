case node[:platform]
when 'darwin'
  execute 'brew install helix' do
    not_if 'which hx'
  end
else
  raise NotImplementedError
end
