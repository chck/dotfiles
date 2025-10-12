case node[:platform]
when 'darwin'
  execute 'brew install --cask thebrowsercompany-dia' do
    not_if 'test -d /Applications/Dia.app/'
  end
else
  raise NotImplementedError
end
