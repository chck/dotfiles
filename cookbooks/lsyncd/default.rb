case node[:platform]
when 'darwin'
  execute 'brew install rsync lsyncd lua' do
    not_if 'which rsync && which lsyncd && which lua'
  end
  execute 'brew install --cask macfuse' do
    not_if 'brew list --cask | grep macfuse'
  end
  execute 'brew install gromgit/fuse/sshfs-mac fswatch progress' do
    not_if 'which sshfs && which fswatch && which progress'
  end
else
  raise NotImplementedError
end
