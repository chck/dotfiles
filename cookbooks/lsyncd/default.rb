case node[:platform]
when 'darwin'
  execute 'brew install rsync lsyncd lua' do
    not_if 'which rsync && which lsyncd && which lua'
  end
else
  raise NotImplementedError
end
