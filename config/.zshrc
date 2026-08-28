# ~/bin holds scripts such as `up`. Set before the zsh-defer'd sources below so
# they resolve in non-interactive shells too. typeset -U keeps this idempotent.
typeset -U path
path=("$HOME/bin" $path)

fpath+=~/.zfunc
autoload -Uz compinit && compinit

# override source function
source ~/.zsh/lib/functions.zsh
# source with zcompile and zsh-defer source (lazy load)
source ~/.zsh/lib/plugins.zsh
zsh-defer source ~/.zsh/lib/basic.zsh
zsh-defer source ~/.zsh/lib/aliases.zsh
zsh-defer source ~/.zsh/lib/languages.zsh
zsh-defer source ~/.zsh/lib/apps.zsh
zsh-defer source ~/.zsh/lib/completion.zsh

# Environment-local configurations
if [ -f ~/.zshrc.`uname` ]; then zsh-defer source ~/.zshrc.`uname`; fi
if [ -f ~/.zshrc.local ]; then zsh-defer source ~/.zshrc.local; fi

# restore built-in source function
zsh-defer unfunction source

# Added by Antigravity IDE
export PATH="$HOME/.antigravity-ide/antigravity-ide/bin:$PATH"
