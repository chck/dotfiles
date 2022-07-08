case node[:platform]
when 'darwin'
  execute 'brew install hugo' do
    not_if 'which hugo'
  end
else
  raise NotImplementedError
end
