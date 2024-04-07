case node[:platform]
when 'darwin'
  execute 'brew install --cask elgato-stream-deck' do
    not_if 'test -d /Applications/Elgato Stream Deck.app/'
  end
else
  raise NotImplementedError
end
