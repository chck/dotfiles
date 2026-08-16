case node[:platform]
when 'darwin'
  execute 'brew install --cask ubersicht' do
    not_if 'test -d /Applications/Übersicht.app/'
  end
  dotfile 'widgets' do
    source 'ubersicht/widgets'
    destination "#{ENV['HOME']}/Library/Application Support/Übersicht"
  end
else
  raise NotImplementedError
end
