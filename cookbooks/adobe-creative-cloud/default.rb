case node[:platform]
when 'darwin'
  execute 'brew install --cask adobe-creative-cloud' do
    not_if 'brew list --cask | grep adobe-creative-cloud'
  end
else
  raise NotImplementedError
end
