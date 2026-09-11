case node[:platform]
when 'darwin'
  include_cookbook 'mas'
  execute 'mas get 6477840170' do
    not_if 'test -d /Applications/Orb.app/'
  end
else
  raise NotImplementedError
end
