case node[:platform]
when 'darwin'
  execute 'brew install --cask font-jetbrains-mono-nerd-font' do
    not_if 'test ~/Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf'
  end
else
  raise NotImplementedError
end
