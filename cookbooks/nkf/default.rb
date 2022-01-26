case node[:platform]
when 'darwin'
  execute 'brew install nkf' do
    not_if 'which nkf'
  end
when 'ubuntu'
  execute 'sudo apt install -y nkf'
when 'redhat'
  execute 'yum install nkf'
else
  raise NotImplementedError
end
