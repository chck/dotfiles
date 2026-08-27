# Mise
eval "$(mise activate zsh)"

# Go
export GOPATH=$HOME/go
export GOBIN=$GOPATH/1.20.5/bin
export PATH=$GOPATH/bin:$PATH

# Deno
export PATH=$HOME/.deno/bin:$PATH

# JavaScript
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$HOME/.local/bin:$PATH"
export PNPM_HOME="$HOME/Library/pnpm"
# pnpm >= 10 links global binaries into $PNPM_HOME/bin and refuses to install
# while that directory is off PATH. $PNPM_HOME itself stays for the shims an
# older pnpm wrote there directly, and is searched after it.
for dir in "$PNPM_HOME" "$PNPM_HOME/bin"; do
  case ":$PATH:" in
    *":$dir:"*) ;;
    *) export PATH="$dir:$PATH" ;;
  esac
done

# Python
export PIPENV_VENV_IN_PROJECT=true
# https://github.com/pypa/pipenv/issues/1914
export PIPENV_SKIP_LOCK=true
