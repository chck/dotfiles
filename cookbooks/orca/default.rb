case node[:platform]
when 'darwin'
  execute 'brew tap stablyai/orca' do
    not_if 'brew tap | grep -q stablyai/orca'
  end
  execute 'brew install --cask stablyai/orca/orca' do
    not_if 'test -d /Applications/Orca.app/'
  end
else
  raise NotImplementedError
end

# The orca-cli, orca-linear and computer-use agent skills are declared in
# config/apm/apm.yml under stablyai/orca/skills/ and deployed by the
# `apm install -g` in cookbooks/claude, which writes them to
# ~/.config/claude/skills/ for Claude Code and ~/.agents/skills/ for every
# other agent. Do not run `npx skills add ... --global` here: it installs to one
# directory only and leaves no declaration in this repository.
