case node[:platform]
when 'darwin'
  execute 'brew install travis' do
    not_if 'which travis'
  end
else
  raise NotImplementedError
end
