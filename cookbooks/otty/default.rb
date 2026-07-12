case node[:platform]
when 'darwin'
  execute 'brew install --cask otty' do
    not_if 'test -d /Applications/Otty.app/'
  end
else
  raise NotImplementedError
end
