case node[:platform]
when 'darwin'
  execute 'brew install --cask agentsview' do
    not_if 'test -d /Applications/AgentsView.app'
  end
else
  raise NotImplementedError
end

# Opt out of the PostHog telemetry and the GitHub release check. Telemetry has
# no config-file switch, only these environment variables, so they cover the
# `agentsview` CLI started from a shell. The desktop app launched from Finder
# does not read ~/.zsh/lib.
execute '''cat <<EOF >> ~/.zsh/lib/apps.zsh

# agentsview
export AGENTSVIEW_TELEMETRY_ENABLED=0
export AGENTSVIEW_DISABLE_UPDATE_CHECK=1
export AGENTSVIEW_DESKTOP_AUTOUPDATE=0
EOF
''' do
  not_if 'grep AGENTSVIEW_TELEMETRY_ENABLED ~/.zsh/lib/apps.zsh'
end
