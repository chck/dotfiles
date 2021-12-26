case node[:platform]
when 'darwin'
  execute 'brew install --cask google-japanese-ime' do
    not_if 'test -d /Applications/GoogleJapaneseInput.localized/'
  end
else
  raise NotImplementedError
end
