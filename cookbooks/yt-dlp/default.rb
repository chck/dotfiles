case node[:platform]
when 'darwin'
  execute 'brew install yt-dlp' do
    not_if 'which yt-dlp'
  end
else
  raise NotImplementedError
end
