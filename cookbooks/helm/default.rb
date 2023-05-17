case node[:platform]
when 'darwin'
  execute 'brew install helm' do
    not_if 'which helm'
  end
else
  raise NotImplementedError
end
