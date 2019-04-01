case node[:platform]
when 'darwin'
  execute 'brew install cookiecutter' do
    not_if 'which cookiecutter'
  end
else
  raise NotImplementedError
end
