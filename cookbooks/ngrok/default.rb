case node[:platform]
when 'darwin'
  execute 'brew cask install ngrok' do
    not_if 'which ngrok'
  end
else
  raise NotImplementedError
end
