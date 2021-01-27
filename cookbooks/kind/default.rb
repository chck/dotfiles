case node[:platform]
when 'darwin'
  execute 'brew install kind' do
    not_if 'which kind'
  end
else
  raise NotImplementedError
end

