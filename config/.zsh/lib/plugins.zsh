source ~/.zplug/init.zsh

zplug "themes/wedisagree", from:oh-my-zsh
zplug "junegunn/fzf-bin", as:command, from:gh-r, rename-to:fzf
zplug "b4b4r07/enhancd", use:init.sh
zplug "zsh-users/zsh-syntax-highlighting", defer:2
zplug "zsh-users/zsh-autosuggestions", defer:2
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-history-substring-search", hook-build:"__zsh_version 5.3"
zplug "stedolan/jq", from:gh-r, as:command
zplug "b4b4r07/emoji-cli", if:"which jq"

zplug check --verbose || zplug install
zplug load

plugins=(git history history-substring-search mysql ruby rails gem brew rake zsh-completions kubectl)

# enhancd
export ENHANCD_HOOK_AFTER_CD=ls

# Pipenv
export PIPENV_VENV_IN_PROJECT=1
