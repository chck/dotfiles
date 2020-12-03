case node[:platform]
when 'darwin'
  execute 'mas install 1351639930' do
    not_if 'test -d /Applications/Gifski.app/'
  end
else
  raise NotImplementedError
end
