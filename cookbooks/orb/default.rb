case node[:platform]
when 'darwin'
  execute 'mas install 6477840170' do
    not_if 'test -d /Applications/Orb.app/'
  end
else
  raise NotImplementedError
end
