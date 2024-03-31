case node[:platform]
when 'darwin'
  execute 'brew install dprint' do
    not_if 'which dprint'
  end
else
  raise NotImplementedError
end
