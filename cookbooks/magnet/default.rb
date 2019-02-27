case node[:platform]
when 'darwin'
  execute 'mas install 441258766' do
    not_if 'test -d /Applications/Magnet.app/'
  end
else
  raise NotImplementedError
end
