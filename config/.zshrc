source ~/.zsh/lib/plugins.zsh
source ~/.zsh/lib/basic.zsh
source ~/.zsh/lib/aliases.zsh
source ~/.zsh/lib/completion.zsh
source ~/.zsh/lib/functions.zsh
source ~/.zsh/lib/languages.zsh
source ~/.zsh/lib/apps.zsh

# Environment-local configurations
if [ -f ~/.zshrc.`uname` ]; then source ~/.zshrc.`uname`; fi
if [ -f ~/.zshrc.local ]; then source ~/.zshrc.local; fi

fpath+=~/.zfunc
autoload -Uz compinit && compinit

