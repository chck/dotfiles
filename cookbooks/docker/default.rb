case node[:platform]
when 'darwin'
  execute 'brew install docker-slim' do
    not_if 'which slim'
  end
  # Rancher
  execute 'brew install --cask rancher' do
    not_if 'test -d /Applications/Rancher\ Desktop.app'
  end
  execute 'brew install lima' do
    not_if 'which lima'
  end
  package 'qemu' do
    not_if 'which qemu-system-aarch64'
  end
  dotfile 'docker.yaml'
  dotfile 'docker-vz.yaml'
when 'ubuntu'
  execute 'sudo apt install -y ca-certificates curl gnupg lsb-release' do
    not_if "dpkg -l | grep '^ii' | grep ca-certificates"
    not_if "dpkg -l | grep '^ii' | grep curl"
    not_if "dpkg -l | grep '^ii' | grep gnupg"
    not_if "dpkg -l | grep '^ii' | grep lsb-release"
  end
  # Rancher
  cmd = <<EOS
curl -s https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Release.key | gpg --dearmor | sudo dd status=none of=/usr/share/keyrings/isv-rancher-stable-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/isv-rancher-stable-archive-keyring.gpg] https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/ ./' | sudo dd status=none of=/etc/apt/sources.list.d/isv-rancher-stable.list
sudo apt update
sudo apt install rancher-desktop
EOS
  execute cmd do
    not_if 'which rancher-desktop'
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
