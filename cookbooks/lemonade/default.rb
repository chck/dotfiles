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
else
  raise NotImplementedError
end

github_binary 'lemonade' do
  raw_url "https://github.com/lemonade-command/lemonade/releases/download/v1.1.1/lemonade_#{platform}_#{arch}.tar.gz"
  not_if "which lemonade"
end
