execute 'curl https://mise.run | sh' do
  not_if 'which mise'
end

# python
execute "mise use --g python@latest" do
  not_if "mise ls python"
end
execute "mise use -g poetry@latest" do
  not_if "which poetry"
end
execute "poetry config virtualenvs.in-project true" do
  not_if "poetry config virtualenvs.in-project | grep true"
end
execute "mise plugins install -y uv && mise use --global uv@latest" do
  not_if "which uv"
end

# node
execute "mise use --global node@latest" do
  not_if "mise ls node"
end
execute "mise use --global pnpm@latest -y" do
  not_if "which pnpm"
end

# terraform
execute "mise use --global terraform@latest" do
  not_if "mise ls terraform"
end
