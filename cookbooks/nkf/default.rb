case node[:platform]
when 'darwin'
  execute 'brew install nkf' do
    not_if 'which nkf'
  end
when 'ubuntu'
  execute 'sudo apt install -y nkf' do
    not_if 'which nkf'
  end
when 'redhat'
  execute 'yum install nkf' do
    not_if 'which nkf'
  end
else
  raise NotImplementedError
end
