case node[:platform]
when 'darwin'
  execute 'brew install --cask miro' do
    not_if 'test -d /Applications/miro.app/'
  end
else
  raise NotImplementedError
end
