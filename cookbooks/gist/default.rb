case node[:platform]
when 'darwin'
  execute 'brew install gist' do
    not_if 'which gist'
  end
else
  raise NotImplementedError
end
