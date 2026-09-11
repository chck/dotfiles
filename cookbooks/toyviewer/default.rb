case node[:platform]
when 'darwin'
  include_cookbook 'mas'
  execute 'mas get 414298354' do
    not_if 'test -d /Applications/ToyViewer.app/'
  end
else
  raise NotImplementedError
end
