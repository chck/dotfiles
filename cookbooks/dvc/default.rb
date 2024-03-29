case node[:platform]
when 'darwin'
  execute 'brew install dvc' do
    not_if 'which dvc'
  end
when 'ubuntu'
  execute 'pipx install "dvc[gs]"' do
    not_if 'which dvc'
  end
else
  raise NotImplementedError
end
