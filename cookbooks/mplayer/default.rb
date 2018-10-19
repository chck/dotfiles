case node[:platform]
when 'darwin'
  execute 'brew install mplayer'
else
  raise NotImplementedError
end
