case node[:platform]
when 'darwin'
  execute 'brew install --cask agentsview' do
    not_if 'test -d /Applications/AgentsView.app'
  end
else
  raise NotImplementedError
end

# Opt out of the PostHog telemetry. It has no config-file switch, only this
# environment variable, so it covers the `agentsview` CLI started from a shell.
# The desktop app launched from Finder does not read ~/.zsh/lib.
execute '''cat <<EOF >> ~/.zsh/lib/apps.zsh

# agentsview
export AGENTSVIEW_TELEMETRY_ENABLED=0
EOF
''' do
  not_if 'grep AGENTSVIEW_TELEMETRY_ENABLED ~/.zsh/lib/apps.zsh'
end
