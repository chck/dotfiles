case node[:platform]
when 'darwin'
  execute 'brew install mpv' do
    not_if 'which mpv'
  end
else
  raise NotImplementedError
end
