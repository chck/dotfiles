#!/bin/sh

set -ex

if [ ! -f config/.config/nvim/dein/repos/github.com/Shougo/dein.vim/.git ]; then
  git submodule init && git submodule update --depth 1
fi

bin/setup

case "$(uname)" in
  "Darwin")  bin/mitamae local $@ lib/recipe.rb ;;
  *) bin/mitamae local $@ lib/recipe.rb ;;
esac
