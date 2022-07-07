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

execute "anyenv install pyenv" do
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

execute "anyenv install rbenv" do
  not_if "which rbenv"
end
ruby_version = "2.7.6"
execute "rbenv install #{ruby_version} && rbenv global #{ruby_version}" do
  not_if "rbenv versions | grep #{ruby_version}"
end
