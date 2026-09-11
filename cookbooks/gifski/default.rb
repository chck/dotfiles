case node[:platform]
when 'darwin'
  include_cookbook 'mas'
  execute 'mas get 1351639930' do
    not_if 'test -d /Applications/Gifski.app/'
  end
else
  raise NotImplementedError
end
