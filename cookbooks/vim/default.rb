# package 'vim' do
#   options '--with-python3 --with-lua'
# end

#execute 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh)" ~/.vim/bundles'

dotfile '.vim'
dotfile '.vimrc'

execute "vim -c 'call dein#install() | q!'"
