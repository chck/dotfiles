alias ..="cd .."
alias ...="cd ../.."

alias g="git"
alias s="git status -sb"

# cargo-script
alias rust="cargo-script"
# bat replaces cat
alias cat="bat"
# exa replaces ls
alias ls="exa -a"
# procs replaces ps
alias ps="procs"
# lazydocker
alias lzd="lazydocker"
# Kubernetes
source <(kubectl completion zsh)
alias k=kubectl
complete -o default -F __start_kubectl k
# fd replaces find
alias find="fd"
