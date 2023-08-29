case node[:platform]
when 'darwin'
  execute 'mas install 929507092' do
    not_if 'test -d /Applications/PhotoScapeX.app/'
  end
else
  raise NotImplementedError
end

