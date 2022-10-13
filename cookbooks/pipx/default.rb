case node[:platform]
when 'darwin'
  execute 'brew install pipx' do
    not_if 'which pipx'
  end
when 'ubuntu'
  execute 'python3 -m pip install --user pipx' do
    not_if 'which pipx'
  end
else
  raise NotImplementedError
end

execute 'pipx install pyscaffold' do
  not_if 'which putup'
end
