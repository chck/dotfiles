case node[:platform]
when 'darwin'
  execute 'brew install mysql' do
    not_if 'which mysql'
  end
else
  raise NotImplementedError
end
