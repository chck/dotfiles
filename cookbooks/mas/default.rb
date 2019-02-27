case node[:platform]
when 'darwin'
  execute 'brew install mas' do
    not_if 'which mas'
  end
else
  raise NotImplementedError
end
