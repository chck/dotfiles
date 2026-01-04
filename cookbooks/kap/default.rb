case node[:platform]
when 'darwin'
  execute 'brew install --cask kap' do
    not_if 'which hadolint'
    not_if 'test -d /Applications/Kap.app/'
  end
else
  raise NotImplementedError
end

