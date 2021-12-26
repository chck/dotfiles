case node[:platform]
when 'darwin'
  execute 'brew install --cask discord' do
    not_if 'test -d /Applications/Discord.app/'
  end
else
  raise NotImplementedError
end
