case node[:platform]
when 'darwin'
  execute 'brew install --cask firealpaca' do
    not_if 'test -d /Applications/FireAlpaca.app'
  end
else
  raise NotImplementedError
end
