case node[:platform]
when 'darwin'
  execute 'brew install --cask slack' do
    not_if 'test -d /Applications/Slack.app/'
  end
else
  raise NotImplementedError
end
