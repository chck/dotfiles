case node[:platform]
when 'darwin'
  # the cask ships a pkg installer, so this step needs sudo
  execute 'brew install --cask zoom' do
    not_if 'test -d /Applications/zoom.us.app/'
  end
else
  raise NotImplementedError
end
