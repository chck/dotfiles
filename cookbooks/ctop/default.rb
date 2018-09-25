case node[:platform]
when 'darwin'
  url = 'https://github.com/bcicen/ctop/releases/download/v0.7.1/ctop-0.7.1-darwin-amd64'
when 'ubuntu'
  url = 'https://github.com/bcicen/ctop/releases/download/v0.7.1/ctop-0.7.1-linux-amd64'
when 'redhat'
  url = 'https://github.com/bcicen/ctop/releases/download/v0.7.1/ctop-0.7.1-linux-arm64'
else
  raise NotImplementedError
end

github_binary 'ctop' do
  raw_url url
end

