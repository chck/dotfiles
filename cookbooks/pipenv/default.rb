case node[:platform]
when 'darwin'
  execute 'brew install pipenv' do
    not_if 'which pipenv'
  end
else
  raise NotImplementedError
end
