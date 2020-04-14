alias ..="cd .."
alias ...="cd ../.."

alias g="git"
alias s="git status -sb"

# cargo-script
alias rust="cargo-script"
# bat
alias cat="bat"
# exa
alias ls="exa -a"
# procs
alias ps="procs"

# lazydocker
alias lzd="lazydocker"

# Kubernetes
source <(kubectl completion zsh)
alias k=kubectl
complete -o default -F __start_kubectl k
