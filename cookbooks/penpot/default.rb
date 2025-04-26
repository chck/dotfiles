case node[:platform]
when 'darwin'
  execute 'wget https://github.com/author-more/penpot-desktop/releases/download/v0.13.0/Penpot-Desktop-0.13.0-arm64.dmg -P /tmp && open /tmp/Penpot-Desktop-0.13.0-arm64.dmg' do
    not_if 'test -d /Applications/Penpot\ Desktop.app/'
  end
else
  raise NotImplementedError
end

