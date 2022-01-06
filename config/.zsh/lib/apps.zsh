# Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
if [ -f ${HOME}/google-cloud-sdk/path.zsh.inc ]; then
  source ${HOME}/google-cloud-sdk/path.zsh.inc
fi
# The next line enables shell command completion for gcloud.
if [ -f ${HOME}/google-cloud-sdk/completion.zsh.inc ]; then
  source ${HOME}/google-cloud-sdk/completion.zsh.inc
fi
export CLOUDSDK_PYTHON=python3

# Docker
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# LIMA
export DOCKER_HOST=unix:///${HOME}/.lima/docker/sock/docker.sock
