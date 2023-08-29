case node[:platform]
when 'darwin'
  execute 'mas install 1219074514' do
    not_if 'test -d /Applications/Vectornator.app/'
  end
else
  raise NotImplementedError
end

