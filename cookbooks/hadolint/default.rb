case node[:platform]
when 'darwin'
  execute 'brew install hadolint' do
    not_if 'which hadolint'
  end
else
  raise NotImplementedError
end
