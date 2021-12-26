if node[:platform] == 'darwin'
  dotfile '.zshrc.darwin'
  execute "sudo chsh -s /bin/zsh #{node[:user]}" do
    not_if 'test $SHELL == /bin/zsh'
  end
else
  package 'zsh'
  dotfile '.zshrc.Linux'
  execute "chsh -s /bin/zsh #{node[:user]}" do
    not_if 'test $SHELL == /bin/zsh'
    only_if "getent passwd #{node[:user]} | cut -d: -f7 | grep -q '^/bin/bash$'"
    user 'root'
  end
end

dotfile '.zplug'
dotfile '.zsh'
dotfile '.zshrc'

# chef (itamae) can not execute 'source command'.
# you need to do 'source ~/.zshrc' manually to load zshrc.
# http://lists.opscode.com/sympa/arc/chef/2013-09/msg00021.html
#
# execute "source ~/.zshrc" do
# end
