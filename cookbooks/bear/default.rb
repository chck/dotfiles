case node[:platform]
when 'darwin'
  execute 'mas install 1091189122' do
    not_if 'test -d /Applications/Bear.app/'
  end
else
  raise NotImplementedError
end
