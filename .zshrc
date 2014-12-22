# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="robbyrussell"
#ZSH_THEME="random"
#ZSH_THEME="theunraveler"
#ZSH_THEME="tjkirch"
#ZSH_THEME="candy"
#ZSH_THEME="bureau"
#ZSH_THEME="pmcgee"
ZSH_THEME="wedisagree"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git history history-substring-search mysql ruby rails gem brew rake rbenv autojump)
#oh-my-zshを有効化
source $ZSH/oh-my-zsh.sh

# User configuration

export PATH="/Applications/SublimeText.app/Contents/SharedSupport/bin:/Users/chck/.rbenv/shims:/usr/local/opt/pyenv/shims:/usr/local/bin:/usr/bin:/bin:/usr/sbin"
export LANG=en_US.UTF-8
#export PYENV_ROOT=$HOMEBREW_PATH/opt/pyenv
#if [ -s $HOMEBREW_PATH/bin/pyenv ] ; then
#  eval "$(pyenv init -)"
#  pyenv global 2.7.6
#  pyenv version | sed -e 's/ .*//'
#fi ]
#java encoding
JAVAC='javac -encoding UTF-8 -J-Dfile.encoding=UTF-8'
alias javac=$JAVAC
JAVA='java -Dfile.encoding=UTF-8'
alias java=$JAVA

#便利機能
########################################
# cd したら自動的にpushdする
setopt auto_pushd
# 重複したディレクトリを追加しない
setopt pushd_ignore_dups
# = の後はパス名として補完する
setopt magic_equal_subst
# 同時に起動したzshの間でヒストリを共有する
setopt share_history
# 同じコマンドをヒストリに残さない
setopt hist_ignore_all_dups
# ヒストリファイルに保存するとき、すでに重複したコマンドがあったら古い方を削除する
setopt hist_save_nodups
# スペースから始まるコマンド行はヒストリに残さない
setopt hist_ignore_space
# ヒストリに保存するときに余分なスペースを削除する
setopt hist_reduce_blanks
# 補完候補が複数あるときに自動的に一覧表示する
setopt auto_menu
# 高機能なワイルドカード展開を使用する
setopt extended_glob
# ^R で履歴検索をするときに * でワイルドカードを使用出来るようにする
bindkey '^R' history-incremental-pattern-search-backward

#エイリアス
alias vim='/usr/local/bin/vim'
alias vi='vim'
alias la='ls -a'
alias lf='ls -F | grep /'
alias lt='ls -ltr'
alias rm='rmtrash'    #~/.Trashがゴミ箱
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
#alias vim='/usr/local/bin/vim'
#alias vi='vim'
alias mkdir='mkdir -p'
alias sudo='sudo '    # sudo の後のコマンドでエイリアスを有効にする
# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'
#systemに同じgemがあったらそちらが使われるのを回避
alias bundle install="bundle install --path vendor/bundle  --disable-shared-gems"
alias tac='tail -r'
alias git add='git add --all'
setopt auto_cd
cdpath=(.. ~ ~/src)
function chpwd() { ls }
eval "$(rbenv init -)"
export PATH=./vendor/bin:$PATH
#pyenv
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"

#zshrc.localがあればそちらを読み込む
[ -f ~/.zshrc.local ] && source ~/.zshrc.local ]
