# complete / of dir name
setopt auto_param_slash
setopt mark_dirs

# case insensitive
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'

# bun
[ -s "$HOME/.bun/_bun" ] && builtin source "$HOME/.bun/_bun"
