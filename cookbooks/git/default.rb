package 'git'

dotfile '.gitconfig' do
  not_if 'test -f ~/.gitconfig'
end
dotfile '.gitignore_global' do
  not_if 'test -f ~/.gitignore_global'
end

case node[:platform]
when 'darwin'
  execute 'brew install git-lfs' do
    not_if 'git lfs'
  end
  execute 'brew tap microsoft/git && brew install --cask git-credential-manager' do
    not_if 'which git-credential-manager'
  end
  execute 'brew install gh' do
    not_if 'which gh'
  end
when 'ubuntu'
  execute ' sudo apt install -y git-lfs' do
    not_if 'git lfs'
  end
  execute 'sudo apt install -y gpg' do
    not_if 'which gpg'
  end
  execute 'sudo apt install -y pass' do
    not_if 'which pass'
  end
  cmd = <<EOS
wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.5.0/gcm-linux_amd64.2.5.0.deb
sudo dpkg -i gcm-linux_amd64.2.5.0.deb
git-credential-manager configure
rm gcm-linux_amd64.2.5.0.deb
EOS
  execute cmd do
    not_if 'which git-credential-manager'
  end
  # ref: https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt
  cmd = <<EOS
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y
EOS
  execute cmd do
    not_if 'which gh'
  end
else
  raise NotImplementedError
end

execute 'gh extension install github/gh-copilot' do 
  not_if 'gh extension list | grep github/gh-copilot'
end
