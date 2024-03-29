case node[:platform]
when 'darwin'
  execute 'brew install --cask keyclu' do
    not_if 'test -d /Applications/KeyClu.app/'
  end
else
  raise NotImplementedError
end
