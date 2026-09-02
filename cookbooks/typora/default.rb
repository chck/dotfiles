case node[:platform]
when 'darwin'
  execute 'brew install --cask typora' do
    not_if 'test -d /Applications/Typora.app/'
  end
else
  raise NotImplementedError
end
