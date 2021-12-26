case node[:platform]
when 'darwin'
  execute 'brew install --cask notion' do
    not_if 'test -d /Applications/Notion.app/'
  end
else
  raise NotImplementedError
end
