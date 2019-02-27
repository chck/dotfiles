case node[:platform]
when 'darwin'
  execute 'mas install 771955779' do
    not_if 'test -d /Applications/Gifted.app/'
  end
else
  raise NotImplementedError
end
