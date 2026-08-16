case node[:platform]
when 'darwin'
  execute 'brew install --cask aqua-voice' do
    not_if 'test -d "/Applications/Aqua Voice.app"'
  end
else
  raise NotImplementedError
end
