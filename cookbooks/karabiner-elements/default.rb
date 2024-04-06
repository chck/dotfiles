case node[:platform]
when 'darwin'
  execute 'brew install --cask karabiner-elements' do
    not_if 'test -d /Applications/karabiner-elements.app/'
  end
  execute 'brew install yqrashawn/goku/goku' do
    not_if 'which goku'
  end
else
  raise NotImplementedError
end
