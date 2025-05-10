case node[:platform]
when 'darwin'
  execute 'brew install --cask amazon-photos' do
    not_if 'test -d /Applications/Amazon\ Photos.app'
  end
else
  raise NotImplementedError
end
