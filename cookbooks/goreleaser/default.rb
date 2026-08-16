case node[:platform]
when 'darwin'
  execute 'brew trust --cask goreleaser/tap/goreleaser && brew install --cask goreleaser/tap/goreleaser' do
    not_if 'which goreleaser'
  end
else
  raise NotImplementedError
end
