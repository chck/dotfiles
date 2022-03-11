case node[:platform]
when 'darwin'
  execute 'mas install 980577198' do
    not_if 'test -d /Applications/Tunacan.app/'
  end
else
  raise NotImplementedError
end
