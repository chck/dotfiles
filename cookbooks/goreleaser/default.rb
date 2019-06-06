case node[:platform]
when 'darwin'
  execute 'brew install goreleaser/tap/goreleaser' do
    not_if 'which goreleaser'
  end
else
  raise NotImplementedError
end
