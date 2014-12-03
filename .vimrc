"---------------------------
" Start Neobundle Settings.
"---------------------------
" bundleで管理するディレクトリを指定
set runtimepath+=~/.vim/bundle/neobundle.vim/
 
" Required:
call neobundle#begin(expand('~/.vim/bundle/'))
 
" neobundle自体をneobundleで管理
NeoBundleFetch 'Shougo/neobundle.vim'
 
" 今後このあたりに追加のプラグインをどんどん書いて行きます！！"
NeoBundle 'Townk/vim-autoclose'
NeoBundle 'thinca/vim-quickrun'
NeoBundle 'scrooloose/syntastic'
NeoBundle 'drillbits/nyan-modoki.vim' 
NeoBundle 'Lokaltog/vim-easymotion'
NeoBundle 'Shougo/unite.vim'
NeoBundle 'Shougo/neomru.vim'
NeoBundle 'derekwyatt/vim-scala'
NeoBundle 'davidhalter/jedi-vim'
NeoBundle 'Shougo/neocomplete.vim'
NeoBundle 'kevinw/pyflakes-vim'
NeoBundle 'nathanaelkane/vim-indent-guides'

call neobundle#end()
 
" Required:
filetype plugin indent on
 
" 未インストールのプラグインがある場合、インストールするかどうかを尋ねてくれるようにする設定
" 毎回聞かれると邪魔な場合もある
NeoBundleCheck
 
"-------------------------
" End Neobundle Settings.
"-------------------------

"-------------------------
" Start config of plugin
" ------------------------

" neocomplete_on
let g:neocomplete#enable_at_startup = 1
if !exists('g:neocomplete#force_omni_input_patterns')
  let g:neocomplete#force_omni_input_patterns = {}
endif
let g:neocomplete#force_omni_input_patterns.ruby = '[^. *\t]\.\w*\|\h\w*::'

" syntastic
let g:syntastic_javascript_checker = "jshint" "JavaScriptのSyntaxチェックはjshintで
let g:syntastic_check_on_open = 0 "ファイルオープン時にはチェックをしない
let g:syntastic_check_on_save = 1 "ファイル保存時にはチェックを実施
let g:syntastic_mode_map = {
            \ 'mode': 'active',
            \ 'active_filetypes': ['php', 'coffeescript', 'sh', 'vim'],
            \ 'passive_filetypes': ['html', 'haskell', 'python']
            \}

" nyan-modoki
set laststatus=2
set statusline=%F%m%r%h%w[%{&ff}]%=%{g:NyanModoki()}(%l,%c)[%P]
let g:nyan_modoki_select_cat_face_number = 2
let g:nayn_modoki_animation_enabled= 1

" jedi-vim
autocmd FileType python setlocal omnifunc=jedi#completions
let g:jedi#completions_enabled = 0
let g:jedi#auto_vim_configuration = 0
"let g:neocomplete#force_omni_input_patterns.python = '\%([^. \t]\.\|^\s*@\|^\s*from\s.\+import \|^\s*from \|^\s*import \)\w*'
let g:neocomplete#force_omni_input_patterns.python = '\h\w*\|[^. \t]\.\w*'


command! -nargs=0 JediRename :call jedi#rename()
" pythonのrename用のマッピングがquickrunとかぶるため回避させる
let g:jedi#rename_command = ""
let g:jedi#documentation_command = "k"

"let g:neobundle_default_git_protocol='git'
":e をvimfilerに置き換え
let g:vimfiler_as_default_explorer=1
" safe mode 解除
let g:vimfiler_safe_mode_by_default=0


"------------------------------------
" neocomplete.vim
"------------------------------------
"Note: This option must set it in .vimrc(_vimrc).  NOT IN .gvimrc(_gvimrc)!
" Disable AutoComplPop.
let g:acp_enableAtStartup = 0
" Use neocomplete.
let g:neocomplete#enable_at_startup = 1
" Use smartcase.
let g:neocomplete#enable_smart_case = 1
" Set minimum syntax keyword length.
let g:neocomplete#sources#syntax#min_keyword_length = 3
let g:neocomplete#lock_buffer_name_pattern = '\*ku\*'
" Plugin key-mappings.
inoremap <expr><C-g>     neocomplete#undo_completion()
inoremap <expr><C-l>     neocomplete#complete_common_string()

" Recommended key-mappings.
" <CR>: close popup and save indent.
inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
function! s:my_cr_function()
  " return neocomplete#close_popup() . "\<CR>"
  " For no inserting <CR> key.
  return pumvisible() ? neocomplete#close_popup() : "\<CR>"
endfunction
" <TAB>: completion.
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"
" <C-h>, <BS>: close popup and delete backword char.
inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
inoremap <expr><C-y>  neocomplete#close_popup()
inoremap <expr><C-e>  neocomplete#cancel_popup()

" Close popup by <Space>.
inoremap <expr><Space> pumvisible() ? neocomplete#close_popup() : "\<Space>"

" autocmd FileType python setlocal omnifunc=pythoncomplete#Complete


set number "行番号を表示する.
set tabstop=2 "タブ幅を2文字にする.
set shiftwidth=2 "自動で挿入されるインテントのタブ幅.
set hlsearch "検索語句のハイライト.
set showmatch "対応する括弧をハイライトする.
set autoindent "自動でインデントさせる.
set cindent "C言語のスタイルでインデントさせる.
set showcmd "コマンドを表示する.
set ignorecase "検索時に大文字小文字を無視する.
set nowrapscan "検索をファイルの先頭へループしない
set incsearch "インクリメンタルサーチ（1文字入力する毎に検索）を実行.
set backspace=indent,eol,start "vimでdelete,backspaceが効かない対応
set clipboard+=unnamed "vimでクリップボード
"タブ、空白、改行の可視化
set list
set listchars=tab:>.,trail:_,eol:↲,extends:>,precedes:<,nbsp:%
set tabstop=2
set autoindent
set expandtab
set shiftwidth=2
"ルーラーを表示
set ruler
set title
"色テーマ.
set t_Co=256
let g:molokai_original = 1 
colorscheme molokai
syntax on

autocmd BufNewFile *.rb 0r ~/.vim/templates/rb.tpl
autocmd BufNewFile *.py 0r ~/.vim/templates/py.tpl
autocmd BufNewFile *.java 0r ~/.vim/templates/java.tpl

autocmd FileType * setlocal formatoptions-=ro

"[JAVA] :Makeでコンパイル
autocmd FileType java :command! Make call s:Make()
function! s:Make()
  :w
  let path = expand("%")
  let syn = "javac ".path
  let dpath = split(path,".java$")
  let ret = system(syn)
  if ret == ""
    :echo "=======\r\nCompile Success"
  else
    :echo "=======\r\nCompile Failure\r\n".ret 
  endif
endfunction

"[JAVA] :Exeでコンパイルしてから実行
autocmd FileType java :command! Exe call s:Javac()
function! s:Javac()
  :w
  let path = expand("%")
  let syn = "javac ".path
  let dpath = split(path,".java$")
  let ret = system(syn)
  if ret == ""
    :echo "=======\r\nCompile Success"
    let syn = "java ".dpath[0]
    let ret = system(syn)
    :echo "=======\r\n実行結果:\r\n".ret
  else
    :echo "=======\r\nCompile Failure\r\n".ret
  endif
endfunction

"自動インデント
set ts=2
set autoindent
filetype plugin indent on

"easymotion
" もっともよく使うであろう'<Leadr><Leader>s'motion を`s`に割り当てます"
nmap s <Plug>(easymotion-s)
vmap s <Plug>(easymotion-s)
omap z <Plug>(easymotion-s) " surround.vimとかぶるので`z`

"全角スペースをハイライト表示
function! ZenkakuSpace()
  highlight ZenkakuSpace cterm=reverse ctermfg=DarkMagenta gui=reverse guifg=DarkMagenta
endfunction

if has('syntax')
  augroup ZenkakuSpace
    autocmd!
    autocmd ColorScheme       * call ZenkakuSpace()
    autocmd VimEnter,WinEnter * match ZenkakuSpace /　/
  augroup END
  call ZenkakuSpace()
endif

" insertモードから抜ける
inoremap <silent> jk <ESC>
inoremap <silent> jj <ESC>
inoremap <silent> <C-j> j
inoremap <silent> kk <ESC>
inoremap <silent> <C-k> k

" unite grep に ag(The Silver Searcher) を使う
if executable('ag')
  let g:unite_source_grep_command = 'ag'
  let g:unite_source_grep_default_opts = '--nogroup --nocolor --column'
  let g:unite_source_grep_recursive_opt = ''
endif

" python
" NeoBundle 'dhalter/jedi-vim'
" NeoBundle 'git@github.com:davidhalter/jedi-vim.git'
