" neobundle"{{{
filetype plugin indent off     " required!

" initialize"{{{
if has('vim_starting')
  let bundle_dir = '~/.bundle'
  if !isdirectory(bundle_dir.'/neobundle.vim')
    call system( 'git clone https://github.com/Shougo/neobundle.vim.git '.bundle_dir.'/neobundle.vim')
  endif

  exe 'set runtimepath+='.bundle_dir.'/neobundle.vim'
  call neobundle#rc(bundle_dir)
endif

augroup MyNeobundle
  au!
  au Syntax vim syntax keyword vimCommand NeoBundle NeoBundleLazy NeoBundleSource NeoBundleFetch
augroup END
"}}}

" 暫定customize {{{
function! Neo_al(ft) "{{{
  return { 'autoload' : {
      \ 'filetype' : a:ft
      \ }}
endfunction"}}}
function! Neo_operator(mappings) "{{{
  return {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \   'mappings' : a:mappings
        \ }}
endfunction"}}}
function! BundleLoadDepends(bundle_names) "{{{
  if !exists('g:loaded_bundles')
    let g:loaded_bundles = {}
  endif

  " bundleの読み込み
  if !has_key( g:loaded_bundles, a:bundle_names )
    execute 'NeoBundleSource '.a:bundle_names
    let g:loaded_bundles[a:bundle_names] = 1
  endif
endfunction"}}}
"}}}

" コマンドを伴うやつの遅延読み込み
function! BundleWithCmd(bundle_names, cmd) "{{{
  call BundleLoadDepends(a:bundle_names)

  " コマンドの実行
  if !empty(a:cmd)
    execute a:cmd
  endif
endfunction "}}}
"bundle"{{{
" その他 {{{
NeoBundle 'Shougo/vimproc', {
      \ 'build' : {
      \     'mac' : 'make -f make_mac.mak',
      \     'unix' : 'make -f make_unix.mak',
      \    },
      \ }
NeoBundleLazy 'taichouchou2/vim-endwise.git', {
      \ 'autoload' : {
      \   'insert' : 1,
      \ } }
" }}}

" 補完 {{{
NeoBundleLazy 'Shougo/neocomplcache', {
      \ 'autoload' : {
      \   'insert' : 1,
      \ }}
NeoBundleLazy 'Shougo/neosnippet', {
      \ 'autoload' : {
      \   'insert' : 1,
      \ }}
NeoBundleLazy 'Shougo/neosnippet-snippets', {
      \ 'autoload' : {
      \   'insert' : 1,
      \ }}
"NeoBundle 'Shougo/neocomplcache-rsense', {
"      \ 'depends': 'Shougo/neocomplcache',
"      \ 'autoload': { 'filetypes': 'ruby' }}
"NeoBundleLazy 'taichouchou2/rsense-0.3', {
"      \ 'build' : {
"      \    'mac': 'ruby etc/config.rb > ~/.rsense',
"      \    'unix': 'ruby etc/config.rb > ~/.rsense',
"      \ } }
" }}}

" 便利 {{{
" 範囲指定のコマンドが使えないので、tcommentのLazy化はNeoBundleのアップデートを待ちましょう...
NeoBundle 'tomtom/tcomment_vim'
NeoBundleLazy 'tpope/vim-surround', {
      \ 'autoload' : {
      \   'mappings' : [
      \     ['nx', '<Plug>Dsurround'], ['nx', '<Plug>Csurround'],
      \     ['nx', '<Plug>Ysurround'], ['nx', '<Plug>YSurround'],
      \     ['nx', '<Plug>Yssurround'], ['nx', '<Plug>YSsurround'],
      \     ['nx', '<Plug>YSsurround'], ['vx', '<Plug>VgSurround'],
      \     ['vx', '<Plug>VSurround']
      \ ]}}
" }}}

" ruby / railsサポート {{{
NeoBundle 'tpope/vim-rails'
NeoBundleLazy 'ujihisa/unite-rake', {
      \ 'depends' : 'Shougo/unite.vim' }
NeoBundleLazy 'basyura/unite-rails', {
      \ 'depends' : 'Shjkougo/unite.vim' }
"NeoBundleLazy 'taichouchou2/unite-rails_best_practices', {
"      \ 'depends' : 'Shougo/unite.vim',
"      \ 'build' : {
"      \    'mac': 'gem install rails_best_practices',
"      \    'unix': 'gem install rails_best_practices',
"      \   }
"      \ }
"NeoBundleLazy 'taichouchou2/unite-reek', {
"      \ 'build' : {
"      \    'mac': 'gem install reek',
"      \    'unix': 'gem install reek',
"      \ },
"      \ 'autoload': { 'filetypes': ['ruby', 'eruby', 'haml'] },
"      \ 'depends' : 'Shougo/unite.vim' }
"NeoBundleLazy 'taichouchou2/alpaca_complete', {
"      \ 'depends' : 'tpope/vim-rails',
"      \ 'build' : {
"      \    'mac':  'gem install alpaca_complete',
"      \    'unix': 'gem install alpaca_complete',
"      \   }
"      \ }

let s:bundle_rails = 'unite-rails unite-rails_best_practices unite-rake alpaca_complete'

function! s:bundleLoadDepends(bundle_names) "{{{
  " bundleの読み込み
  execute 'NeoBundleSource '.a:bundle_names
  au! MyAutoCmd
endfunction"}}}
aug MyAutoCmd
  au User Rails call <SID>bundleLoadDepends(s:bundle_rails)
aug END

" reference環境
"NeoBundleLazy 'vim-ruby/vim-ruby', {
"    \ 'autoload' : { 'filetypes': ['ruby', 'eruby', 'haml'] } }
"NeoBundleLazy 'taka84u9/vim-ref-ri', {
"      \ 'depends': ['Shougo/unite.vim', 'thinca/vim-ref'],
"      \ 'autoload': { 'filetypes': ['ruby', 'eruby', 'haml'] } }
"NeoBundleLazy 'skwp/vim-rspec', {
"      \ 'autoload': { 'filetypes': ['ruby', 'eruby', 'haml'] } }
"NeoBundleLazy 'ruby-matchit', {
"    \ 'autoload' : { 'filetypes': ['ruby', 'eruby', 'haml'] } }
" }}}

" }}}

" Installation check. "{{{
if neobundle#exists_not_installed_bundles()
  echomsg 'Not installed bundles : ' .
        \ string(neobundle#get_not_installed_bundle_names())
  echomsg 'Install Plugins'
  NeoBundleInstall
endif
"}}}
filetype plugin indent on
"}}}
" plugin settings"{{{
"------------------------------------
" endwise.vim
"------------------------------------
"{{{
let g:endwise_no_mappings=1
"}}}

"------------------------------------
" vim-surround
"------------------------------------
" {{{
nmap ds  <Plug>Dsurround
nmap cs  <Plug>Csurround
nmap ys  <Plug>Ysurround
nmap yS  <Plug>YSurround
nmap yss <Plug>Yssurround
nmap ySs <Plug>YSsurround
nmap ySS <Plug>YSsurround
xmap S   <Plug>VSurround
xmap gS  <Plug>VgSurround
vmap s   <Plug>VSurround

" surround_custom_mappings.vim"{{{
let g:surround_custom_mapping = {}
let g:surround_custom_mapping._ = {
      \ 'p':  "<pre> \r </pre>",
      \ 'w':  "%w(\r)",
      \ }
let g:surround_custom_mapping.help = {
      \ 'p':  "> \r <",
      \ }
let g:surround_custom_mapping.ruby = {
      \ '-':  "<% \r %>",
      \ '=':  "<%= \r %>",
      \ '9':  "(\r)",
      \ '5':  "%(\r)",
      \ '%':  "%(\r)",
      \ 'w':  "%w(\r)",
      \ '#':  "#{\r}",
      \ '3':  "#{\r}",
      \ 'e':  "begin \r end",
      \ 'E':  "<<EOS \r EOS",
      \ 'i':  "if \1if\1 \r end",
      \ 'u':  "unless \1unless\1 \r end",
      \ 'c':  "class \1class\1 \r end",
      \ 'm':  "module \1module\1 \r end",
      \ 'd':  "def \1def\1\2args\r..*\r(&)\2 \r end",
      \ 'p':  "\1method\1 do \2args\r..*\r|&| \2\r end",
      \ 'P':  "\1method\1 {\2args\r..*\r|&|\2 \r }",
      \ }
let g:surround_custom_mapping.javascript = {
      \ 'f':  "function(){ \r }"
      \ }
let g:surround_custom_mapping.lua = {
      \ 'f':  "function(){ \r }"
      \ }
let g:surround_custom_mapping.python = {
      \ 'p':  "print( \r)",
      \ '[':  "[\r]",
      \ }
let g:surround_custom_mapping.vim= {
      \'f':  "function! \r endfunction"
      \ }
"}}}
"}}}

"------------------------------------
" neocomplcache
"------------------------------------
" 補完・履歴 neocomplcache "{{{
set infercase

"----------------------------------------
" neocomplcache
let g:neocomplcache_enable_at_startup = 1

" default config"{{{
let g:neocomplcache_force_overwrite_completefunc = 1
let g:neocomplcache#sources#rsense#home_directory = expand('~/.bundle/rsense-0.3')
let g:neocomplcache_enable_camel_case_completion = 1
let g:neocomplcache_enable_underbar_completion = 1
let g:neocomplcache_skip_auto_completion_time = '0.3'
"}}}

" keymap {{{
imap <expr><C-g>     neocomplcache#undo_completion()
imap <expr><CR>      neocomplcache#smart_close_popup() . "<CR>" . "<Plug>DiscretionaryEnd"
imap <silent><expr><S-TAB> pumvisible() ? "\<C-P>" : "\<S-TAB>"
" imap <silent><expr><TAB>   pumvisible() ? "\<C-N>" : "\<TAB>"
imap <expr><TAB> neosnippet#expandable() ? "\<Plug>(neosnippet_jump_or_expand)" : pumvisible() ? "\<C-n>" : "\<TAB>"
" }}}
"}}}

"------------------------------------
" neosnippet
"------------------------------------
" neosnippet "{{{

" snippetを保存するディレクトリを設定してください
" example
" let s:default_snippet = neobundle#get_neobundle_dir() . '/neosnippet/autoload/neosnippet/snippets' " 本体に入っているsnippet
" let s:my_snippet = '~/snippet' " 自分のsnippet
" let g:neosnippet#snippets_directory = s:my_snippet
" let g:neosnippet#snippets_directory = s:default_snippet . ',' . s:my_snippet
imap <silent><C-F>                <Plug>(neosnippet_expand_or_jump)
inoremap <silent><C-U>            <ESC>:<C-U>Unite snippet<CR>
nnoremap <silent><Space>e         :<C-U>NeoSnippetEdit -split<CR>
smap <silent><C-F>                <Plug>(neosnippet_expand_or_jump)
" xmap <silent>o                    <Plug>(neosnippet_register_oneshot_snippet)
"}}}

"------------------------------------
" vim-rails
"------------------------------------
""{{{
"有効化
let g:rails_default_file='config/database.yml'
let g:rails_level = 4
let g:rails_mappings=1
let g:rails_modelines=0
" let g:rails_some_option = 1
" let g:rails_statusline = 1
" let g:rails_subversion=0
" let g:rails_syntax = 1
" let g:rails_url='http://localhost:3000'
" let g:rails_ctags_arguments='--languages=-javascript'
" let g:rails_ctags_arguments = ''
function! SetUpRailsSetting()
  nnoremap <buffer><Space>r :R<CR>
  nnoremap <buffer><Space>a :A<CR>
  nnoremap <buffer><Space>m :Rmodel<Space>
  nnoremap <buffer><Space>c :Rcontroller<Space>
  nnoremap <buffer><Space>v :Rview<Space>
  nnoremap <buffer><Space>p :Rpreview<CR>
endfunction

aug MyAutoCmd
  au User Rails call SetUpRailsSetting()
aug END

aug RailsDictSetting
  au!
aug END
"}}}

"------------------------------------
" Unite-rails.vim
"------------------------------------
"{{{
function! UniteRailsSetting()
  nnoremap <buffer><C-H><C-H><C-H>  :<C-U>Unite rails/view<CR>
  nnoremap <buffer><C-H><C-H>       :<C-U>Unite rails/model<CR>
  nnoremap <buffer><C-H>            :<C-U>Unite rails/controller<CR>

  nnoremap <buffer><C-H>c           :<C-U>Unite rails/config<CR>
  nnoremap <buffer><C-H>s           :<C-U>Unite rails/spec<CR>
  nnoremap <buffer><C-H>m           :<C-U>Unite rails/db -input=migrate<CR>
  nnoremap <buffer><C-H>l           :<C-U>Unite rails/lib<CR>
  nnoremap <buffer><expr><C-H>g     ':e '.b:rails_root.'/Gemfile<CR>'
  nnoremap <buffer><expr><C-H>r     ':e '.b:rails_root.'/config/routes.rb<CR>'
  nnoremap <buffer><expr><C-H>se    ':e '.b:rails_root.'/db/seeds.rb<CR>'
  nnoremap <buffer><C-H>ra          :<C-U>Unite rails/rake<CR>
  nnoremap <buffer><C-H>h           :<C-U>Unite rails/heroku<CR>
endfunction
aug MyAutoCmd
  au User Rails call UniteRailsSetting()
aug END
"}}}

"----------------------------------------
" vim-ref
"----------------------------------------
"{{{
let g:ref_open                    = 'split'
let g:ref_refe_cmd                = expand('~/.vim/ref/ruby-ref1.9.2/refe-1_9_2')

nnoremap rr :<C-U>Unite ref/refe     -default-action=split -input=
nnoremap ri :<C-U>Unite ref/ri       -default-action=split -input=

aug MyAutoCmd
  au FileType ruby,eruby,ruby.rspec nnoremap <silent><buffer>KK :<C-U>Unite -no-start-insert ref/ri   -input=<C-R><C-W><CR>
  au FileType ruby,eruby,ruby.rspec nnoremap <silent><buffer>K  :<C-U>Unite -no-start-insert ref/refe -input=<C-R><C-W><CR>
aug END
"}}}

"------------------------------------
" Unite-reek, Unite-rails_best_practices
"------------------------------------
" {{{
nnoremap <silent> [unite]<C-R>      :<C-u>Unite -no-quit reek<CR>
nnoremap <silent> [unite]<C-R><C-R> :<C-u>Unite -no-quit rails_best_practices<CR>
" }}}
"}}}

":e をvimfilerに置き換え
let g:vimfiler_as_default_explorer=1
" safe mode 解除
let g:vimfiler_safe_mode_by_default=0

"行番号を表示する.
set number
"タブ幅を2文字にする.
set tabstop=2
"自動で挿入されるインテントのタブ幅.
set shiftwidth=2
"検索語句のハイライト.
set hlsearch
"対応する括弧をハイライトする.
set showmatch
"自動でインデントさせる.
set autoindent
"C言語のスタイルでインデントさせる.
set cindent
"コマンドを表示する.
set showcmd
"検索時に大文字小文字を無視する.
set ignorecase
"検索をファイルの先頭へループしない.
set nowrapscan
"インクリメンタルサーチ（1文字入力する毎に検索）を実行.
set incsearch
"vimでdelete,backspaceが効かない時に
set backspace=indent,eol,start
"vimでクリップボード
set clipboard+=unnamed

"色テーマ.
set t_Co=256
let g:molokai_original = 1 
colorscheme molokai
syntax on

autocmd BufNewFile *.rb 0r ~/.vim/templates/rb.tpl

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

NeoBundle 'Lokaltog/vim-easymotion'
NeoBundle 'git://github.com/Shougo/unite.vim.git'
NeoBundle 'Shougo/neomru.vim'

"easymotion
" もっともよく使うであろう'<Leadr><Leader>s'motion を`s`に割り当てます"
nmap s <Plug>(easymotion-s)
vmap s <Plug>(easymotion-s)
omap z <Plug>(easymotion-s) " surround.vimとかぶるので`z`

"タブ、空白、改行の可視化
set list
set listchars=tab:>.,trail:_,eol:↲,extends:>,precedes:<,nbsp:%

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

set tabstop=2
set autoindent
set expandtab
set shiftwidth=2

" insertモードから抜ける
inoremap <silent> jk <ESC>
inoremap <silent> jj <ESC>
inoremap <silent> <C-j> j
inoremap <silent> kk <ESC>
inoremap <silent> <C-k> k

"ルーラーを表示
set ruler
set title

NeoBundle 'Shougo/neomru.vim'
NeoBundle 'derekwyatt/vim-scala'

" Unite.vim
" 起動時にインサートモードで開始
 let g:unite_enable_start_insert = 1
"最近開いたファイル履歴の保存数
let g:unite_source_file_mru_limit = 100
" nnoremap [unite]    <Nop>
nmap     <Space>u [unite]
" project以下のファイル一覧
nnoremap <silent> [unite]o :<C-u>Unite file_rec/async:! -no-split<CR>
nnoremap <silent> [unite]c :<C-u>UniteWithCurrentDir -buffer-name=files buffer file_mru bookmark file<CR>
nnoremap <silent> [unite]b :<C-u>Unite buffer<CR>
" カレントファイル一覧
nnoremap <silent> [unite]l :<C-u>UniteWithBufferDir -buffer-name=files file -no-split<CR>
" 最近使用したファイル一覧
nnoremap <silent> [unite]r :<C-u>Unite file_mru -no-split<CR>

let g:unite_source_history_yank_enable =1  "history/yankの有効化
nnoremap <silent> <C-y> :<C-u>Unite history/yank -no-split<CR>
inoremap <silent> <C-y> <ESC>:<C-u>Unite history/yank -no-split<CR>

" grep検索
nnoremap <silent> [unite]g :<C-u>Unite grep:. -buffer-name=search-buffer<CR>

" unite grep に ag(The Silver Searcher) を使う
if executable('ag')
  let g:unite_source_grep_command = 'ag'
  let g:unite_source_grep_default_opts = '--nogroup --nocolor --column'
  let g:unite_source_grep_recursive_opt = ''
endif
