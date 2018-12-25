package 'vim' do
  options '--with-lua --with-override-system-vi --with-python3'
end

#execute 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh)" ~/.vim/bundles'

dotfile '.vim'
dotfile '.vimrc'
dotfile '.ideavimrc' if node[:platform] == 'darwin'

execute "vim -c 'call dein#install() | q!'"
