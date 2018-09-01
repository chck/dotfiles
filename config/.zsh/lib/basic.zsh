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

# don't logout by EOF
setopt ignore_eof
