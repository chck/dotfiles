alias ..="cd .."
alias ...="cd ../.."

alias g="git"
alias s="git status -sb"

# rust
alias rust="cargo-script"
# bat
alias cat="bat"
# lazydocker
alias lzd="lazydocker"
# exa
alias ls="exa -a"

# Kubernetes
source <(kubectl completion zsh)
alias k=kubectl
complete -o default -F __start_kubectl k
