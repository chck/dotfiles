case node[:platform]
when 'darwin'
  execute 'brew install mplayer' do
    not_if 'which mplayer'
  end
else
  raise NotImplementedError
end
