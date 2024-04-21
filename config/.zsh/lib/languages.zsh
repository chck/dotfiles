# mise (asdf)
eval "$(~/.local/bin/mise activate zsh)"

# Rust
export PATH=$HOME/.cargo/bin:$PATH

# Go
export GOPATH=$HOME/go
export GOBIN=$GOPATH/1.20.5/bin
export PATH=$GOPATH/bin:$PATH

# Deno
export PATH=$HOME/.deno/bin:$PATH

# JavaScript
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$HOME/.local/bin:$PATH"

export PIPENV_VENV_IN_PROJECT=true
# https://github.com/pypa/pipenv/issues/1914
export PIPENV_SKIP_LOCK=true
