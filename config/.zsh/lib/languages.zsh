# Anyenv
export PATH=$HOME/.anyenv/bin:$PATH
eval "$(anyenv init -)"

# Rust
export PATH=$HOME/.cargo/bin:$PATH

# Go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# Python
export PATH=$HOME/.poetry/bin:$PATH
export PIPENV_VENV_IN_PROJECT=true
# https://github.com/pypa/pipenv/issues/1914
export PIPENV_SKIP_LOCK=true
