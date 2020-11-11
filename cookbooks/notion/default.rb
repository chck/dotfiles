case node[:platform]
when 'darwin'
  execute 'brew cask install notion' do
    not_if 'test -d /Applications/Notion.app/'
  end
else
  raise NotImplementedError
end
