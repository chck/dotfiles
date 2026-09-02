case node[:platform]
when 'darwin'
  execute 'brew tap stablyai/orca' do
    not_if 'brew tap | grep -q stablyai/orca'
  end
  execute 'brew install --cask stablyai/orca/orca' do
    not_if 'test -d /Applications/Orca.app/'
  end
else
  raise NotImplementedError
end
