# XDG configuration path
export XDG_CONFIG_HOME="$HOME/.config"
# Google Cloud SDK
if [[ "$OSTYPE" == darwin* ]]; then
  # Homebrew Cask installs to $HOMEBREW_PREFIX/share/google-cloud-sdk/
  if [ -f "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.zsh.inc" ]; then . "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.zsh.inc"; fi
  if [ -f "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOMEBREW_PREFIX/share/google-cloud-sdk/completion.zsh.inc"; fi
else
  # curl installer puts SDK in $HOME/google-cloud-sdk/
  if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi
  if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
fi
export CLOUDSDK_PYTHON=python3
# Kubectl
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
# Docker
export DOCKER_BUILDKIT=1
export DOCKER_HOST=unix://$HOME/.rd/docker.sock
export COMPOSE_DOCKER_CLI_BUILD=1
export COMPOSE_BAKE=true
# direnv
export EDITOR=vim
eval "$(direnv hook zsh)"
# pre-commit
export PRE_COMMIT_COLOR=always
# ghq
export GHQ_ROOT=~/Works
# Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
# git-wt
eval "$(git wt --init zsh)"
# claude
export CLAUDE_CONFIG_DIR=$XDG_CONFIG_HOME/claude
# headroom
export HEADROOM_TELEMETRY=off
# aqua
export PATH="$HOME/.local/share/aquaproj-aqua/bin:$PATH"
