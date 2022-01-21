case node[:platform]
when 'darwin'
  execute 'brew install hub' do
    not_if 'which hub'
  end
when 'ubuntu'
  execute 'sudo apt install -y hub' do
    not_if 'which hub'
  end
else
  raise NotImplementedError
end
