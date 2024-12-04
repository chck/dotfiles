case node[:platform]
when 'darwin'
  execute 'brew install jaq' do
    not_if "which jaq"
  end
else
  raise NotImplementedError
end
