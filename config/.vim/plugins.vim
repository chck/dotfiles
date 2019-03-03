let s:dein_dir = expand('~/.vim/bundles')

if &compatible
 set nocompatible
endif
" Add the dein installation directory into runtimepath
set runtimepath+=~/.vim/bundles/repos/github.com/Shougo/dein.vim

if dein#load_state(s:dein_dir)
 call dein#begin(s:dein_dir)

 call dein#add(s:dein_dir)
 call dein#add('Shougo/deoplete.nvim')
 if !has('nvim')
   call dein#add('roxma/nvim-yarp')
   call dein#add('roxma/vim-hug-neovim-rpc')
 endif
 let g:deoplete#enable_at_startup = 1

 call dein#end()
 call dein#save_state()
endif

filetype plugin indent on
syntax enable
