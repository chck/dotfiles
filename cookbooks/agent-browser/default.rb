case node[:platform]
when 'darwin'
  execute 'brew install agent-browser' do
    not_if 'which agent-browser'
  end
  # Downloads Chrome for Testing into ~/.agent-browser/browsers/. The command is
  # idempotent on its own, but it re-checks the upstream version every run and
  # would pull a fresh 180MB build whenever Chrome for Testing moves, so it is
  # guarded on the download directory instead. Remove that directory to upgrade.
  execute 'agent-browser install' do
    not_if 'test -d "$HOME/.agent-browser/browsers"'
  end
else
  raise NotImplementedError
end

# The agent-browser skill is declared in config/apm/apm.yml as
# vercel-labs/agent-browser/skills/agent-browser and deployed by the
# `apm install -g` in cookbooks/claude. It is a discovery stub: the usage guide
# is served by the CLI itself (`agent-browser skills get core`), so the skill is
# useless without the brew install above.
