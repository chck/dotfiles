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

execute '''cat <<EOF >> ~/.zsh/lib/apps.zsh

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
EOF
''' do
  not_if 'grep DOCKER_BUILDKIT ~/.zsh/lib/apps.zsh'
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh

# Kubernetes
source <(kubectl completion zsh)
alias k=kubectl
complete -o default -F __start_kubectl k
EOF
''' do
  not_if 'grep kubectl ~/.zsh/lib/aliases.zsh'
end


execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# Docker
alias d=docker
EOF
''' do
  not_if 'grep "# Docker" ~/.zsh/lib/aliases.zsh'
end
