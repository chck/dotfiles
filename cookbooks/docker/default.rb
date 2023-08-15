docker_compose_version = '2.20.3'
docker_compose_path = '~/.docker/cli-plugins/docker-compose'
case node[:platform]
when 'darwin'
  execute 'brew install docker-slim' do
    not_if 'which slim'
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
    execute "mkdir -p ~/.docker/cli-plugins && curl -L https://github.com/docker/compose/releases/download/v#{docker_compose_version}/docker-compose-darwin-aarch64 -o #{docker_compose_path} && sudo chmod +x #{docker_compose_path}" do
      not_if "docker compose version | grep v#{docker_compose_version}"
    end
    dotfile 'docker.yaml'
  end
when 'ubuntu'
  execute 'sudo apt install -y ca-certificates curl gnupg lsb-release' do
    not_if "dpkg -l | grep '^ii' | grep ca-certificates"
    not_if "dpkg -l | grep '^ii' | grep curl"
    not_if "dpkg -l | grep '^ii' | grep gnupg"
    not_if "dpkg -l | grep '^ii' | grep lsb-release"
  end
  execute 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt update -y && sudo apt install -y docker-ce docker-ce-cli containerd.io' do
    not_if 'which docker'
  end
  # Docker Compose
  execute "mkdir -p ~/.docker/cli-plugins && curl -L https://github.com/docker/compose/releases/download/v#{docker_compose_version}/docker-compose-#{`uname`.downcase.strip}-#{`uname -m`.strip} -o #{docker_compose_path} && sudo chmod +x #{docker_compose_path}" do
    not_if "docker compose version | grep v#{docker_compose_version}"
  end
  # Kubernetes
  execute 'wget "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" -P /tmp && sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl' do
    not_if 'which kubectl'
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
