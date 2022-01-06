case node[:platform]
when 'darwin'
  execute 'brew install --cask stack-stack' do
    not_if 'test -d /Applications/Stack.app'
  end
else
  raise NotImplementedError
end
