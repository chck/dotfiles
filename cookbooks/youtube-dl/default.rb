case node[:platform]
when 'darwin'
  execute 'brew install youtube-dl' do
    not_if 'which youtube-dl'
  end
else
  raise NotImplementedError
end
