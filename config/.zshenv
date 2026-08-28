# Read by every zsh, interactive or not, unlike .zshrc. PATH belongs here so
# scripts in ~/bin (such as `up`) also resolve in non-interactive shells.
# typeset -U keeps repeated sourcing from duplicating entries.
typeset -U path
path=("$HOME/bin" $path)

# Added by Radicle.
path+=("$HOME/.radicle/bin")
