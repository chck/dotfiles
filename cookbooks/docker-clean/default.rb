case node[:platform]
when 'darwin'
  execute 'brew install docker-clean' do
    not_if 'which docker-clean'
  end
else
  raise NotImplementedError
end
