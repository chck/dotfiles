execute 'curl https://mise.run | sh' do
  not_if 'which mise'
end

# python
python_version = "3.11.9"
execute "mise use --global python@#{python_version}" do
  not_if "mise ls python | grep #{python_version}"
end
execute "mise use --global poetry@latest" do
  not_if "which poetry"
end
execute 'poetry config virtualenvs.in-project true' do
  not_if 'poetry config virtualenvs.in-project | grep true'
end

# node
node_version = "21.7.3"
execute "mise use --global node@#{node_version}" do
  not_if "mise ls node | grep #{node_version}"
end
execute "mise use --global pnpm@latest -y" do
  not_if "which pnpm"
end

# terraform
terraform_version = "1.8.1"
execute "mise use --global terraform@#{terraform_version}" do
  not_if "mise ls terraform | grep #{terraform_version}"
end

