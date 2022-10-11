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
  execute "sudo apt install -y libbz2-dev libreadline-dev libsqlite3-dev lzma liblzma-dev" do
    not_if "dpkg -l | grep '^ii' | grep libbz2-dev"
    not_if "dpkg -l | grep '^ii' | grep libreadline-dev"
    not_if "dpkg -l | grep '^ii' | grep libsqlite3-dev"
    not_if "dpkg -l | grep '^ii' | grep lzma"
    not_if "dpkg -l | grep '^ii' | grep liblzma-dev"
  end
end
python_version = "3.8.12"
execute "pyenv install #{python_version} && pyenv global #{python_version} && pip install -U pip && pip install cython pynvim" do
  not_if "pyenv versions | grep #{python_version}"
end

# Ruby
execute "anyenv install -f rbenv" do
  not_if "which rbenv"
end
ruby_version = "3.1.2"
case node[:platform]
when 'ubuntu'
  execute "rbenv install #{ruby_version} && rbenv global #{ruby_version}" do
    not_if "rbenv versions | grep #{ruby_version}"
  end
when 'darwin'
  execute "RUBY_CONFIGURE_OPTS=--with-openssl-dir=$(brew --prefix openssl@1.1) "\
          "LDFLAGS=-L$(brew --prefix openssl@1.1)/lib "\
          "CPPFLAGS=-I$(brew --prefix openssl@1.1)/include "\
          "rbenv install #{ruby_version} && rbenv global #{ruby_version}" do
    not_if "rbenv versions | grep #{ruby_version}"
  end
end

# Node.js
execute "anyenv install -f nodenv" do
  not_if "which nodenv"
end
node_version = "18.6.0"
execute "nodenv install #{node_version} && nodenv global #{node_version}" do
  not_if "nodenv versions | grep #{node_version}"
end
execute 'curl -fsSL https://get.pnpm.io/install.sh | sh -' do
  not_if 'which pnpm'
end

# Go
execute "anyenv install -f goenv" do
  not_if "which goenv"
end
go_version = "1.19.2"
execute "goenv install #{go_version} && goenv global #{go_version}" do
  not_if "goenv versions | grep #{go_version}"
end
