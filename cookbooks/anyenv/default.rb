git "install anyenv" do
  repository "https://github.com/riywo/anyenv.git"
  destination "#{ENV['HOME']}/.anyenv"
end

git "install anyenv-update" do
  repository "https://github.com/znz/anyenv-update.git"
  destination "#{ENV['HOME']}/.anyenv/plugins/anyenv-update"
end
