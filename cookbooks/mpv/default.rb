case node[:platform]
when 'darwin'
  execute 'brew install mpv' do
    not_if 'which mpv'
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.config/mpv/mpv.conf
# https://www.reddit.com/r/mpv/comments/9gopck/how_would_one_make_all_files_loop_by_default/
loop=yes
EOF
''' do
  not_if 'grep loop=yes ~/.config/mpv/mpv.conf'
end
