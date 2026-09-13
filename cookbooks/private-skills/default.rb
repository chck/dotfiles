case node[:platform]
when 'darwin'
  # `gh skill` needs gh 2.98.0 or newer; cookbooks/git installs gh.
  include_cookbook 'git'

  # Skill repositories that must not be named in a public repository — a private
  # repository, or one whose owner identifies an internal org. The mechanism is
  # tracked here, the identifiers are not: one `OWNER/REPO` per line in the file
  # below, `#` comments and blank lines ignored. Same split as `~/.zshrc.local`
  # and `~/.config/mise/conf.d/*.toml`.
  #
  # Public skill repositories do not belong here. Declare those in
  # config/apm/apm.yml, which resolves one skill directory per entry and is
  # readable as a manifest.
  private_skills_list = File.expand_path('~/.config/dotfiles/private-skills')

  # `--all` takes every skill in the repository, `--force` overwrites without
  # prompting, and both agent targets are written on every run: `gh skill` has
  # no "install if absent" mode, and re-copying the same content is the same
  # class of idempotent-by-overwrite command as `apm install -g`.
  #
  # One run per agent, because the two write to different directories.
  # `--agent claude-code` follows CLAUDE_CONFIG_DIR to ~/.config/claude/skills/,
  # `--agent codex` writes ~/.agents/skills/, which every non-Claude agent here
  # reads. Without the codex run the skills exist for Claude Code alone.
  if File.exist?(private_skills_list)
    File.read(private_skills_list).split("\n").each do |line|
      repository = line.sub(/#.*/, '').strip
      next if repository.empty?

      %w[claude-code codex].each do |agent|
        execute "gh skill install #{repository} --all --agent #{agent} --scope user --force" do
          user node[:user]
        end
      end
    end
  end
else
  raise NotImplementedError
end
