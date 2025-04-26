version = "0.7.7"
url_prefix = "https://github.com/bcicen/ctop/releases/download/v#{version}/ctop-#{version}"

case node[:platform]
when 'darwin'
  url = "#{url_prefix}-darwin-amd64"
when 'ubuntu'
  url = "#{url_prefix}-linux-amd64"
when 'redhat'
  url = "#{url_prefix}-linux-arm64"
else
  raise NotImplementedError
end

github_binary 'ctop' do
  raw_url url
end

