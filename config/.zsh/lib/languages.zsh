# Anyenv
export PATH=$HOME/.anyenv/bin:$PATH
eval "$(anyenv init -)"

# mise (asdf)
eval "$(~/.local/bin/mise activate zsh)"

# Rust
export PATH=$HOME/.cargo/bin:$PATH

# Go
export GOPATH=$HOME/go
export GOBIN=$GOPATH/1.20.5/bin
export PATH=$GOPATH/bin:$PATH

# Python
export PIPENV_VENV_IN_PROJECT=true
# https://github.com/pypa/pipenv/issues/1914
export PIPENV_SKIP_LOCK=true
# https://github.com/pyenv/pyenv/issues/1906#issuecomment-834751771
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi
export PATH="$HOME/.poetry/bin:$PATH"

# Deno
export PATH=$HOME/.deno/bin:$PATH

# JavaScript
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$HOME/.local/bin:$PATH"
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Terraform
export PATH="$HOME/.anyenv/envs/tfenv/bin:$PATH"

# Ruby
export PATH="$HOME/.anyenv/envs/rbenv/bin:$PATH"
