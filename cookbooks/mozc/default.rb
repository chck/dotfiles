case node[:platform]
when 'darwin'
  execute 'brew cask install google-japanese-ime' do
    not_if 'test -d /Applications/GoogleJapaneseInput.localized/'
  end
else
  raise NotImplementedError
end
