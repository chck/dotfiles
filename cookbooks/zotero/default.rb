case node[:platform]
when 'darwin'
  execute 'brew install --cask zotero' do
    not_if 'test -d /Applications/Zotero.app/'
  end
else
  raise NotImplementedError
end
