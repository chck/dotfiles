case node[:platform]
when 'darwin'
  execute 'brew install --cask ngrok' do
    not_if 'which ngrok'
  end
else
  raise NotImplementedError
end
