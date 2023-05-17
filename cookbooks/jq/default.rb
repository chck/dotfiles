case node[:platform]
when 'darwin'
  execute 'brew install jq' do
    not_if "which jq"
  end
else
  raise NotImplementedError
end
