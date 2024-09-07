case node[:platform]
when 'darwin'
  execute 'brew install --cask zed' do
    not_if 'test -d /Applications/Zed.app'
  end
  dotfile "zed/settings.json" do
    destination "#{ENV['HOME']}/.config"
  end
when 'ubuntu'
  execute 'curl -f https://zed.dev/install.sh | sh' do
    not_if 'which zed'
  end
else
  raise NotImplementedError
end
