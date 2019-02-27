case node[:platform]
when 'darwin'
  execute 'brew cask install rubymine' do
    not_if 'test -d /Applications/RubyMine.app/'
  end
else
  raise NotImplementedError
end

dotfile '.gemrc'
