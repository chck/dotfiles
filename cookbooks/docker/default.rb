case node[:platform]
when 'darwin'
  execute 'brew install docker-slim' do
    not_if 'which docker-slim'
  end
  case `uname -m`.chomp
  when 'x86_64'  # Intel Mac
    execute 'brew install --cask docker' do
      not_if 'which docker'
    end
  when 'arm64'  # M1 Mac
    execute 'brew install lima' do
      not_if 'which lima'
    end
    package 'qemu' do
      not_if 'which qemu-system-aarch64'
    end
    execute 'brew install docker' do
      not_if 'which docker'
    end
    docker_compose_version = '2.2.3'
    docker_compose_path = '~/.docker/cli-plugins/docker-compose'
    execute "curl -L https://github.com/docker/compose/releases/download/v#{docker_compose_version}/docker-compose-darwin-aarch64 -o #{docker_compose_path} && sudo chmod +x #{docker_compose_path}" do
      not_if 'which docker compose'
    end
    dotfile 'docker.yaml'
    execute '''cat <<EOF >> ~/.zsh/lib/apps.zsh

# LIMA
export DOCKER_HOST=unix://${HOME}/.lima/docker/sock/docker.sock
EOF
    ''' do
      not_if 'grep DOCKER_HOST ~/.zsh/lib/apps.zsh'
    end
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
