package 'vim'

dotfile '.vim'
dotfile '.vimrc'
if node[:platform] == 'darwin'
  dotfile '.ideavimrc' do
    not_if 'test -f ~/.ideavimrc'
  end
end

execute 'curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > /tmp/installer.sh && sh /tmp/installer.sh ~/.vim/bundles' do
  not_if 'test -d ~/.vim/bundles/repos/github.com/Shougo/dein.vim'
end

execute "vim -c 'call dein#install() | q!'" do
  not_if 'test -d ~/.vim/bundles/repos/github.com/Shougo/dein.vim'
end

py38_path = "PATH='/usr/local/opt/python@3.8/bin:$PATH'"
execute "#{py38_path} pip3 install pynvim" do
  not_if "#{py38_path} pip3 list | grep pynvim"
end
