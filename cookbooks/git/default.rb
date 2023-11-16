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
  execute 'brew tap microsoft/git && brew install --cask git-credential-manager-core' do
    not_if 'git credential-manager-core'
  end
  execute 'brew install gh' do
    not_if 'which gh'
  end
when 'ubuntu'
  execute ' sudo apt install -y git-lfs' do
    not_if 'git lfs'
  end
else
  raise NotImplementedError
end

case node[:platform]
when 'darwin'
  execute 'brew install gh' do
    not_if 'which gh'
  end
when 'ubuntu'
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
