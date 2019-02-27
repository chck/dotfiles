case node[:platform]
when 'darwin'
  execute 'brew install watch' do
    not_if 'which watch'
  end
else
  raise NotImplementedError
end
