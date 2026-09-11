include_role 'base'

# Cookbooks are grouped by purpose; add a new one to the section it belongs to.
# Sections are ordered by how early the tool is wanted on a fresh machine, not
# by dependency: a cookbook that needs another one declares it itself, with
# `include_cookbook '<name>'` at the top of its recipe (see cookbooks/sheldon,
# cookbooks/tunacan2). `include_recipe` is idempotent in mitamae, so a cookbook
# pulled in that way runs once no matter how many recipes ask for it, and moving
# an entry within this file cannot break it.
#
# The one ordering rule left is zsh: cookbooks append to ~/.zsh/lib/*.zsh
# through the symlink the zsh cookbook creates, and appending before it exists
# would write a real file where the link belongs. Keep zsh first.

# --- bootstrap ---
include_cookbook 'zsh'
include_cookbook 'git'
include_cookbook 'mise'
include_cookbook 'aqua'
include_cookbook 'rust'
include_cookbook 'mas'

# --- browsers ---
# Early on purpose: the run is sequential, so installing browsers up front lets
# the sign-ins they gate (Google, GitHub, password manager) happen in parallel
# with the rest of the apply instead of after it.
include_cookbook 'brave-browser'
include_cookbook 'google-chrome'
include_cookbook 'arc'
include_cookbook 'dia'

# --- communication ---
# Early for the same reason as browsers: these need a sign-in before they are
# usable, and doing it while the rest of the apply runs costs no extra time.
include_cookbook 'slack'
include_cookbook 'discord'
include_cookbook 'zoom'
include_cookbook 'linear'

# --- shell ---
include_cookbook 'sheldon'
include_cookbook 'starship'
include_cookbook 'fzf'
include_cookbook 'peco'

# --- terminal ---
include_cookbook 'iterm2'
include_cookbook 'ghostty'
include_cookbook 'otty'

# --- git ---
include_cookbook 'git-wt'
include_cookbook 'git-fork'
include_cookbook 'ghq'
include_cookbook 'gibo'
include_cookbook 'gist'
include_cookbook 'commitizen'
include_cookbook 'difftastic'
include_cookbook 'bfg'
include_cookbook 'radicle'

# --- editors / IDE ---
include_cookbook 'vim'
include_cookbook 'helix'
include_cookbook 'zed'
include_cookbook 'typora'
include_cookbook 'pycharm'
include_cookbook 'webstorm'
include_cookbook 'rustrover'
include_cookbook 'datagrip'

# --- AI agents ---
include_cookbook 'claude'
include_cookbook 'gemini'
include_cookbook 'opencode'
include_cookbook 'opencode2'
include_cookbook 'agent-browser'
include_cookbook 'ollama'
include_cookbook 'ax'
include_cookbook 'aqua-voice'
include_cookbook 'orca'

# --- languages / build tooling ---
include_cookbook 'pipx'
include_cookbook 'pipenv'
include_cookbook 'yarn'
include_cookbook 'deno'
include_cookbook 'bazel'
include_cookbook 'swig'
include_cookbook 'llvm'
include_cookbook 'hdf5'
include_cookbook 'evcxr'
include_cookbook 'bacon'

# --- dev tooling / linters ---
include_cookbook 'pre-commit'
include_cookbook 'direnv'
include_cookbook 'dotenvx'
include_cookbook 'hadolint'
include_cookbook 'actionlint'
include_cookbook 'sqruff'
include_cookbook 'dprint'
include_cookbook 'goreleaser'
include_cookbook 'hugo'
include_cookbook 'watchexec'

# --- containers / kubernetes ---
include_cookbook 'docker'
include_cookbook 'lazydocker'
include_cookbook 'ctop'
include_cookbook 'kind'
include_cookbook 'helm'
include_cookbook 'kustomize'
include_cookbook 'kube-score'
include_cookbook 'kubeconform'
include_cookbook 'skaffold'
include_cookbook 'stern'

# --- cloud ---
include_cookbook 'gcloud'
include_cookbook 'awscli'
include_cookbook 'azure-cli'

# --- data / database ---
include_cookbook 'mysql'
include_cookbook 'postgresql'
include_cookbook 'sqlx'
include_cookbook 'csvq'
include_cookbook 'dvc'

# --- network ---
include_cookbook 'httpie'
include_cookbook 'hurl'
include_cookbook 'grpcurl'
include_cookbook 'hey'
include_cookbook 'ngrok'
include_cookbook 'telnet'
include_cookbook 'wget'
include_cookbook 'monolith'
include_cookbook 'tailscale'

# --- security ---
include_cookbook 'yubico-authenticator'
include_cookbook 'oath-toolkit'
include_cookbook 'mkcert'

# --- CLI utilities ---
include_cookbook 'ripgrep'
include_cookbook 'fd'
include_cookbook 'bat'
include_cookbook 'eza'
include_cookbook 'procs'
include_cookbook 'dust'
include_cookbook 'bottom'
include_cookbook 'tree'
include_cookbook 'watch'
include_cookbook 'sd'
include_cookbook 'gnu-sed'
include_cookbook 'jq'
include_cookbook 'jaq'
include_cookbook 'yq'
include_cookbook 'htmlq'
include_cookbook 'nkf'
include_cookbook 'unrar'
include_cookbook 'tokei'
include_cookbook 'tspin'
include_cookbook 'tldr'
include_cookbook 'zat'
include_cookbook 'lsyncd'
include_cookbook 'pastel'

# --- media / graphics ---
include_cookbook 'imagemagick'
include_cookbook 'graphviz'
include_cookbook 'inkscape'
include_cookbook 'potrace'
include_cookbook 'img2pdf'
include_cookbook 'pngpaste'
include_cookbook 'freeze'
include_cookbook 'kap'
include_cookbook 'obs'
include_cookbook 'mpv'
include_cookbook 'vlc'
include_cookbook 'mplayer'
include_cookbook 'yt-dlp'
include_cookbook 'capcut'
include_cookbook 'adobe-creative-cloud'
include_cookbook 'penpot'
include_cookbook 'amazon-photos'
include_cookbook 'scrcpy'

# --- desktop / window management ---
include_cookbook 'aerospace'
include_cookbook 'ubersicht'
include_cookbook 'dockdoor'
include_cookbook 'raycast'
include_cookbook 'bettertouchtool'
include_cookbook 'karabiner-elements'
include_cookbook 'azookey'
include_cookbook 'keyclu'
include_cookbook 'keepingyouawake'
include_cookbook 'font-jetbrains-mono-nerd-font'

# --- system / hardware ---
include_cookbook 'macfuse'
include_cookbook 'puremac'
include_cookbook 'geekbench'
include_cookbook 'displaylink'
include_cookbook 'logitech-g-hub'
include_cookbook 'elgato-stream-deck'
include_cookbook 'elgato-control-center'
include_cookbook 'elgato-wave-link'
include_cookbook 'elgato-capture-device-utility'
include_cookbook 'elgato-camera-hub'

# --- desktop apps ---
include_cookbook 'obsidian'
include_cookbook 'zotero'
include_cookbook 'steam'
include_cookbook 'bathyscaphe'

# --- Mac App Store (needs `mas`) ---
include_cookbook 'bear'
include_cookbook 'line'
include_cookbook 'magnet'
include_cookbook 'toyviewer'
include_cookbook 'gifski'
include_cookbook 'tunacan2'
include_cookbook 'orb'
