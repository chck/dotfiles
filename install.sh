#!/bin/sh

set -ex

if [ ! -f config/.config/nvim/dein/repos/github.com/Shougo/dein.vim/.git ]; then
  git submodule init && git submodule update --depth 1
fi

profile_file="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/profile"
if [ -n "$DOTFILES_PROFILE" ]; then
  mkdir -p "$(dirname "$profile_file")"
  echo "$DOTFILES_PROFILE" > "$profile_file"
elif [ -f "$profile_file" ]; then
  DOTFILES_PROFILE="$(cat "$profile_file")"
else
  echo "DOTFILES_PROFILE is not set. Run: DOTFILES_PROFILE=private|work ./install.sh" >&2
  exit 1
fi
export DOTFILES_PROFILE

bin/setup

case "$(uname)" in
  "Darwin")  bin/mitamae local $@ lib/recipe.rb ;;
  *) bin/mitamae local $@ lib/recipe.rb ;;
esac
