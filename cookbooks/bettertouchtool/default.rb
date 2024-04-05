case node[:platform]
when 'darwin'
  execute 'brew install --cask bettertouchtool' do
    not_if 'test -d /Applications/BetterTouchTool.app/'
  end
else
  raise NotImplementedError
end
