#!/bin/sh

set -ex

# Homebrew does not allow sudo.
case "$(uname)" in
  "Darwin")  itamae local $@ lib/recipe.rb ;;
  *) sudo -E itamae local $@ lib/recipe.rb ;;
esac
