directory '~/.config/mpv' do
  path "#{ENV['HOME']}/.config/mpv"
  action :nothing
end

template '~/.config/mpv/mpv.conf' do
  source :auto
  path "#{ENV['HOME']}/.config/mpv/mpv.conf"
  action :nothing
end

case node[:platform]
when 'darwin'
  execute 'brew install mpv' do
    not_if 'which mpv'
    notifies :create, 'directory[~/.config/mpv]'
    notifies :create, 'template[~/.config/mpv/mpv.conf]'
  end
else
  raise NotImplementedError
end
