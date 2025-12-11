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

# python
execute "mise use --g python@latest" do
  not_if "mise ls python"
end
execute "mise plugin add poetry && mise use -g poetry@latest" do
  not_if "which poetry"
end
#execute "poetry config virtualenvs.in-project true" do
#  not_if "poetry config virtualenvs.in-project | grep true"
#end
execute "mise plugins install -y uv && mise use --global uv@latest" do
  not_if "which uv"
end

# node
execute "mise use --global node@latest" do
  not_if "mise which node"
end
execute "mise use --global pnpm@latest -y" do
  not_if "which pnpm"
end

# rust
execute "mise use --global rust@latest" do
  not_if "mise which rust"
end

# terraform
execute "mise use --global terraform@latest" do
  not_if "mise ls terraform"
end
