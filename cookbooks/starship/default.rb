execute 'curl -sS https://starship.rs/install.sh | sh -s -- -y' do
  not_if 'which starship'
end
dotfile "starship.toml" do
  destination "#{ENV['HOME']}/.config"
end
