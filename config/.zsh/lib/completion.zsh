# use completion
autoload -U compinit
compinit

# complete / of dir name
setopt auto_param_slash
setopt mark_dirs

# case insensitive
zstyle ':completion:*' matcher-list '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'

# Pipenv
export PIPENV_VENV_IN_PROJECT=1
