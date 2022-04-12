case node[:platform]
when 'darwin'
  execute 'brew install --cask keepingyouawake' do
    not_if 'test -d /Applications/Keepingyouawake.app'
  end
else
  raise NotImplementedError
end
