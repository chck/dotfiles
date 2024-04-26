case node[:platform]
when 'darwin'
  execute 'brew install --cask geekbench' do
    not_if 'test -d /Applications/Geekbench\ 6.app'
  end
else
  raise NotImplementedError
end
