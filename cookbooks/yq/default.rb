case node[:platform]
when 'darwin'
  execute 'brew install python-yq' do
    not_if 'yq --help | grep -v "command not found"'
  end
else
  raise NotImplementedError
end
