case node[:platform]
when 'darwin'
  execute 'brew install skaffold' do
    not_if "which skaffold"
  end
else
  raise NotImplementedError
end
