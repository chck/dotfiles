case node[:platform]
when 'darwin'
  include_cookbook 'mas'
  execute 'mas install 929507092' do
    not_if 'test -d /Applications/PhotoScapeX.app/'
  end
else
  raise NotImplementedError
end
