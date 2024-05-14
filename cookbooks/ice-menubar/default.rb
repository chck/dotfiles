case node[:platform]
when 'darwin'
  execute 'brew install jordanbaird-ice' do
    not_if 'test -d /Applications/Ice.app'
  end
else
  raise NotImplementedError
end
