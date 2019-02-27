case node[:platform]
when 'darwin'
  execute 'brew cask install docker' do
    not_if 'which docker'
  end
else
  raise NotImplementedError
end

github_binary 'docker-clean' do
  raw_url 'https://raw.githubusercontent.com/ZZROTDesign/docker-clean/v2.0.4/docker-clean'
end
