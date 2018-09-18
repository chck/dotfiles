case node[:platform]
when 'darwin'
  execute 'brew install nkf'
when 'ubuntu'
  execute 'apt-get install nkf'
when 'redhat'
  execute 'yum install nkf'
else
  raise NotImplementedError
end
