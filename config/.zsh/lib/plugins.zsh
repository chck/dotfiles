# enhancd
export ENHANCD_HOOK_AFTER_CD=ls
export ENHANCD_FILTER="fzf --height 40%:fzy"

# sheldon - zsh plugin manager
# zcompile source files
ensure_zcompiled ~/.zshrc
# cache tips: https://zenn.dev/fuzmare/articles/zsh-plugin-manager-cache
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}
sheldon_cache="$cache_dir/sheldon.zsh"
sheldon_toml="$HOME/.config/sheldon/plugins.toml"
if [[ ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" ]]; then
  sheldon source > $sheldon_cache
fi
source "$sheldon_cache"
unset cache_dir sheldon_cache sheldon_toml

# starship - shell framework
eval "$(starship init zsh)"
