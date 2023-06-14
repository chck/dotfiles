case node[:platform]
when 'darwin'
  execute 'brew install hurl' do
    not_if 'which hurl'
  end
else
  raise NotImplementedError
end
