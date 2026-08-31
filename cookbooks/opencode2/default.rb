case node[:platform]
when 'darwin'
  # OpenCode 2 is the beta that becomes 2.0. It installs as `opencode2` and
  # deliberately does not replace v1's `opencode`, so cookbooks/opencode stays
  # as the stable fallback — see the alias note below.
  #
  # npm is the only supported channel during the beta: Homebrew, Docker and the
  # standalone binaries are all unsupported upstream, and mise cannot reach it
  # either (`mise ls-remote npm:@opencode-ai/cli` lists the 1.18.x stable line
  # only, never the beta dist-tag). Goes through `mise exec` because node is a
  # mise-managed shim and mitamae's /bin/sh does not have it on PATH.
  #
  # Unguarded on purpose. `npm install -g <pkg>@beta` re-resolves the tag and is
  # itself idempotent, which puts it in the same class as the `apm install -g`
  # and `mise install` calls elsewhere in this role. A `not_if 'which opencode2'`
  # would pin the machine to whatever beta happened to land first and never
  # upgrade it, which for a package that publishes daily defeats the point.
  execute 'mise exec -- npm install -g @opencode-ai/cli@beta'

  # No config resource here: v2 reads the same ~/.config/opencode/opencode.json
  # that cookbooks/opencode symlinks, tolerates v1's schema without warnings,
  # and honours its `model` key. The v1 `provider` block is ignored because v2
  # detects a local Ollama server on its own, and v2 already reads the shared
  # rules and skills from ~/.config/opencode/AGENTS.md, ~/.agents/skills and
  # ~/.claude/skills.
else
  raise NotImplementedError
end

# `oc` points at v2 because that is the daily driver. v1 stays installed as the
# fallback and is reachable as plain `opencode`, so it gets no alias of its own.
execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# opencode2
alias oc="opencode2"
EOF
''' do
  not_if { File.exist?(File.expand_path('~/.zsh/lib/aliases.zsh')) && File.read(File.expand_path('~/.zsh/lib/aliases.zsh')).include?('alias oc=') }
end
