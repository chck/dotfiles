case node[:platform]
when 'darwin'
  execute 'brew install --cask goreleaser' do
    not_if 'which goreleaser'
  end
else
  raise NotImplementedError
end
