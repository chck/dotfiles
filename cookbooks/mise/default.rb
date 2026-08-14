case node[:platform]
when 'darwin'
  execute 'brew install mise && eval "$(mise activate zsh)"' do
    not_if 'which mise'
  end
when 'ubuntu'
  execute '''
sudo apt update -y && sudo apt install -y gpg sudo wget curl
sudo install -dm 755 /etc/apt/keyrings
wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1> /dev/null
echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
sudo apt update
sudo apt install -y mise
eval "$(mise activate zsh)"
''' do
    not_if 'which mise'
  end
else
  raise NotImplementedError
end

# Tool versions are declared in config/mise/config.toml and symlinked here, so
# a new machine reproduces the same set. Do NOT add `mise use --global` calls to
# any cookbook: they rewrite the symlinked file and surface as a diff in this
# repository. Add the tool to config/mise/config.toml instead.
#
# Machine-local tools go in ~/.config/mise/conf.d/*.toml, which mise reads
# alongside config.toml and which dotfiles deliberately does not manage.
execute 'mkdir -p ~/.config/mise' do
  not_if 'test -d ~/.config/mise'
end

mise_config = File.join(dotfiles_root, 'config/mise/config.toml')
link File.expand_path('~/.config/mise/config.toml') do
  to mise_config
  user node[:user]
  force true
end

# Runs on every provision so newly declared tools are picked up; a no-op once
# everything is installed.
execute 'mise install'
