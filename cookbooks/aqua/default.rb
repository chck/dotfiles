case node[:platform]
when 'darwin'
  execute 'brew install aqua' do
    not_if 'which aqua'
  end
else
  raise NotImplementedError
end
