git "install anyenv" do
  not_if 'which anyenv'
  repository "https://github.com/riywo/anyenv.git"
  destination "#{ENV['HOME']}/.anyenv"
end

git "install anyenv-update" do
  dest = "#{ENV['HOME']}/.anyenv/plugins/anyenv-update"
  not_if "test -d #{dest}"
  repository "https://github.com/znz/anyenv-update.git"
  destination dest
end
