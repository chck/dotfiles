case node[:platform]
when 'darwin'
  execute 'brew install --cask docker' do
    not_if 'which docker'
  end
  execute 'brew install docker-slim' do
    not_if 'which docker-slim'
  end
else
  raise NotImplementedError
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
