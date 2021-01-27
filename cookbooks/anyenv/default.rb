git "install anyenv" do
  not_if 'which anyenv'
  repository "https://github.com/anyenv/anyenv.git"
  destination "#{ENV['HOME']}/.anyenv"
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

python_version = "3.9.1"
execute "pyenv install #{python_version} && pyenv global #{python_version}" do
  not_if "test #{python_version} == $(python -V | sed -e 's/Python //g')"
end
