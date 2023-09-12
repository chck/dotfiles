git "install anyenv" do
  not_if 'which anyenv'
  repository "https://github.com/anyenv/anyenv.git"
  destination "#{ENV['HOME']}/.anyenv"
end
case node[:platform]
when 'ubuntu'
  execute 'sudo chown -R $(whoami) ~/.anyenv' do
    not_if "ls -l ~/.anyenv | awk '{print $3}' | grep $(whoami)"
  end
end

git "install anyenv-update" do
  dest = "#{ENV['HOME']}/.anyenv/plugins/anyenv-update"
  not_if "test -d #{dest}"
  repository "https://github.com/znz/anyenv-update.git"
  destination dest
end

git "install anyenv-git" do
  dest = "#{ENV['HOME']}/.anyenv/plugins/anyenv-git"
  not_if "test -d #{dest}"
  repository "https://github.com/znz/anyenv-git.git"
  destination dest
end

execute "anyenv install --init --force" do
  not_if "test -d #{ENV['HOME']}/.config/anyenv/anyenv-install"
end

# Python
execute "anyenv install -f pyenv" do
  not_if "which pyenv"
end
if node[:platform] == 'ubuntu'
  execute "sudo apt install -y libbz2-dev libreadline-dev libsqlite3-dev lzma liblzma-dev tk-dev" do
    not_if "dpkg -l | grep '^ii' | grep libbz2-dev"
    not_if "dpkg -l | grep '^ii' | grep libreadline-dev"
    not_if "dpkg -l | grep '^ii' | grep libsqlite3-dev"
    not_if "dpkg -l | grep '^ii' | grep lzma"
    not_if "dpkg -l | grep '^ii' | grep liblzma-dev"
    not_if "dpkg -l | grep '^ii' | grep tk-dev"
  end
end
python_version = "3.9.18"
execute "pyenv install #{python_version} && pyenv global #{python_version} && pip install -U pip && pip install cython pynvim" do
  not_if "pyenv versions | grep #{python_version}"
end

# Node.js
execute "anyenv install -f nodenv" do
  not_if "which nodenv"
end
node_version = "20.2.0"
execute "nodenv install #{node_version} && nodenv global #{node_version}" do
  not_if "nodenv versions | grep #{node_version}"
end
execute 'npm i -g @antfu/ni' do
  not_if 'which ni'
end
execute 'curl -fsSL https://get.pnpm.io/install.sh | sh -' do
  not_if 'which pnpm'
end

