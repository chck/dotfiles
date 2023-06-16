case node[:platform]
when 'darwin'
  execute 'brew install pre-commit' do
    not_if 'which pre-commit'
  end
else
  raise NotImplementedError
end
