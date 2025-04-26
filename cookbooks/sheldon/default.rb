cargo "sheldon"
execute "mkdir -p ~/.config/sheldon" do
  not_if "test -d ~/.config/sheldon"
end
dotfile "sheldon/plugins.toml" do
  destination "#{ENV['HOME']}/.config"
end
