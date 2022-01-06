# Anyenv
export PATH=$HOME/.anyenv/bin:$PATH
eval "$(anyenv init -)"

# Rust
export PATH=$HOME/.cargo/bin:$PATH

# Go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# Python
export PIPENV_VENV_IN_PROJECT=true
# https://github.com/pypa/pipenv/issues/1914
export PIPENV_SKIP_LOCK=true
# https://github.com/pyenv/pyenv/issues/1906#issuecomment-834751771
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

# Deno
export PATH=$HOME/.deno/bin:$PATH
