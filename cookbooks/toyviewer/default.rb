case node[:platform]
when 'darwin'
  execute 'mas install 414298354' do
    not_if 'test -d /Applications/ToyViewer.app/'
  end
else
  raise NotImplementedError
end
