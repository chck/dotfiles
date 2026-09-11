case node[:platform]
when 'darwin'
  include_cookbook 'mas'
  execute 'mas get 980577198' do
    not_if 'test -d /Applications/Tunacan.app/'
  end
else
  raise NotImplementedError
end
