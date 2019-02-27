case node[:platform]
when 'darwin'
  execute 'mas install 539883307' do
    not_if 'test -d /Applications/LINE.app/'
  end
else
  raise NotImplementedError
end
