case node[:platform]
when 'darwin'
  include_cookbook 'mas'
  execute 'mas get 1091189122' do
    not_if 'test -d /Applications/Bear.app/'
  end
else
  raise NotImplementedError
end
