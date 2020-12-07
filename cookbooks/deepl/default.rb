case node[:platform]
when 'darwin'
  execute 'brew install --cask deepl' do
    not_if 'test -d /Applications/DeepL.app/'
  end
else
  raise NotImplementedError
end
