case node[:platform]
when 'darwin'
  execute 'brew install --cask steam' do
    not_if 'test -d /Applications/Steam.app/'
  end
else
  raise NotImplementedError
end
