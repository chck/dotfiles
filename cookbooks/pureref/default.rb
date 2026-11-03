case node[:platform]
when 'darwin'
  include_cookbook 'ax'
  installer = File.join(dotfiles_root, 'cookbooks/pureref/install.rb')
  execute 'install PureRef for personal use' do
    command %(/usr/bin/ruby "#{installer}")
    not_if 'test -d /Applications/PureRef.app'
  end
else
  raise NotImplementedError
end
