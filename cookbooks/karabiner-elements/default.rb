case node[:platform]
when 'darwin'
  execute 'brew install --cask karabiner-elements' do
    not_if 'test -d /Applications/karabiner-elements.app/'
  end
  dotfile "karabiner" do
    destination "#{ENV['HOME']}/.config"
  end
else
  raise NotImplementedError
end
