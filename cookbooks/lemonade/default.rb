case node[:platform]
when 'darwin'
  platform = 'darwin'
when 'ubuntu'
  platform = 'linux'
else
  raise NotImplementedError
end

case `uname -m`.chomp
when 'x86_64'
  arch = '386'
when 'amd64'
  arch = 'amd64'
when 'arm64'
  arch = 'arm64'
else
  raise NotImplementedError
end

version = "v1.1.2"
if arch == 'arm64'
  execute "go install github.com/lemonade-command/lemonade@#{version} && "\
          "cd $GOPATH/1.19.2/pkg/mod/github.com/lemonade-command/lemonade@#{version} && "\
          "GOOS=#{platform} GOARCH=#{arch} sudo go build -ldflags '-s -w -X github.com/lemonade-command/lemonade/lemon.Version=#{version}' -o /usr/local/bin/lemonade" do
    not_if "which lemonade"
  end
else
  github_binary 'lemonade' do
    raw_url "https://github.com/lemonade-command/lemonade/releases/download/#{version}/lemonade_#{platform}_#{arch}.tar.gz"
    not_if "which lemonade"
  end
end
