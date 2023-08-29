case node[:platform]
when 'darwin'
  execute 'wget https://sudovanilla.com/distribute/applications/penpot-desktop/latest/Penpot.dmg -P /tmp && open /tmp/Penpot.dmg' do
    not_if 'test -d /Applications/Penpot Desktop.app/'
  end
else
  raise NotImplementedError
end

