# language
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# auto pushd
setopt auto_pushd
setopt pushd_ignore_dups

# share zsh history
setopt share_history
export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=10000000
export SAVEHIST=60000000

# ignore duplicate history
setopt hist_ignore_all_dups

# don't logout by EOF
setopt ignore_eof

# supress warning for glob no match
setopt nonomatch

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# colorized ls
export LSCOLORS=gxfxcxdxbxegedabagacad
export LS_COLORS='di=36:ln=35:so=32:pi=33:ex=31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
zstyle ':completion:*' list-colors 'di=36' 'ln=35' 'so=32' 'ex=31' 'bd=46;34' 'cd=43;34'

# readline for compiler
export CFLAGS="-I/usr/local/opt/readline/include $CFLAGS"
export LDFLAGS="-L/usr/local/opt/readline/lib $LDFLAGS"

# openssl for compiler
export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include $CFLAGS"
export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib $LDFLAGS"
