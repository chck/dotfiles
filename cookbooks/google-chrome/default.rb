case node[:platform]
when 'darwin'
  execute 'brew install --cask google-chrome' do
    not_if 'test -d /Applications/Google\ Chrome.app/'
  end
else
  raise NotImplementedError
end
