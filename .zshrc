# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="random"
#"3den"
ZSH_THEME="pmcgee"
#"pure"
#"robbyrussell"
#"rkj"

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

#パスの設定
########################################
export LANG=ja_JP.UTF-8   #環境変数
export PATH="/Users/a13446/.rbenv/shims:/usr/local/bin:/Users/a13446/.rbenv/shims:/Users/a13446/.rbenv/shims:/usr/local/bin:/Users/a13446/.rbenv/shims:/usr/local/opt/pyenv/shims:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
export CLASSPATH=$CLASSPATH:.:/Applications/XAMPP/apache-tomcat-7.0.54/lib/servlet-api.jar
#HOMEBREW_PATH=/usr/local
export PYENV_ROOT=$HOMEBREW_PATH/opt/pyenv
if [ -s $HOMEBREW_PATH/bin/pyenv ] ; then
  eval "$(pyenv init -)"
  pyenv global 2.7.6
  pyenv version | sed -e 's/ .*//'
fi
#if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
#export PATH="$HOME/.gem/ruby/2.0.0/bin:$PATH"
#java encoding
JAVAC='javac -encoding UTF-8 -J-Dfile.encoding=UTF-8'
alias javac=$JAVAC
JAVA='java -Dfile.encoding=UTF-8'
alias java=$JAVA
#PATHをあえて指定することで、homebrewのパスの優先度を高める。
export PATH=/usr/local/bin:$PATH
export GRADLE_HOME="usr/local/Cellar/gradle/1.10/libexec/"

#便利機能
########################################
# cdコマンド実行後、lsを実行する
function cd() {
  builtin cd $@ && ls;
}

# プロンプト2行表示
#PROMPT="%{${fg[red]}%}[%n@%m]%{${reset_color}%} %~
#%# "

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

# エイリアス
alias la='ls -a'
alias ll='ls -l'
alias lf='ls -F | grep /'
alias lt='ls -ltr'
alias rm='rmtrash'    #~/.Trashがゴミ箱
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias vim='/usr/local/bin/vim'
alias vi='vim'
alias mkdir='mkdir -p'
alias sudo='sudo '    # sudo の後のコマンドでエイリアスを有効にする
# グローバルエイリアス
alias -g L='| less'
alias -g G='| grep'
alias sc='sbt clean'
#alias gb='grunt build'

#ログイン時にfortuneをcowsay
#function random_cowsay() {
#  COWS=`brew --prefix`/usr/local/Cellar/cowsay/3.03/share/cows
#  NBRE_COWS=$(ls -1 $COWS | wc -l)
#  COWS_RANDOM=$(expr $RANDOM % $NBRE_COWS + 1)
#  COW_NAME=$(ls -1 $COWS | awk -F\. -v COWS_RANDOM_AWK=$COWS_RANDOM 'NR == COWS_RANDOM_AWK {print $1}')
#  cowsay -f $COW_NAME "`Fortune -s`"
#}
#if which fortune cowsay >/dev/null; then
#  while :
#  do
#    random_cowsay 2>/dev/null && break
#  done
#fi && unset -f random_cowsay

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

#zshrc.localがあればそちらを読み込む
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
