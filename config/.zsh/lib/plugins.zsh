source ~/.zplug/init.zsh

zplug "b4b4r07/enhancd", use:init.sh

zplug check --verbose || zplug install
zplug load
