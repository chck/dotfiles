case node[:platform]
when 'darwin'
  execute 'brew install gibo' do
    not_if 'which gibo'
  end
else
  raise NotImplementedError
end
