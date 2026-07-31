case node[:platform]
when 'darwin'
  execute 'brew install --cask capcut' do
    not_if 'test -d /Applications/CapCut.app'
  end
else
  raise NotImplementedError
end
