case node[:platform]
when 'darwin'
  execute 'brew install --cask rustrover' do
    not_if 'test -d /Applications/RustRover.app/'
  end
else
  raise NotImplementedError
end
