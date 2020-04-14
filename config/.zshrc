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

# added by travis gem
[ -f ~/.travis/travis.sh ] && source ~/.travis/travis.sh

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
