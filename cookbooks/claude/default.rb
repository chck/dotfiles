case node[:platform]
when 'darwin'
  execute 'brew install --cask claude' do
    not_if 'test -d /Applications/Claude.app/'
  end
else
  raise NotImplementedError
end
