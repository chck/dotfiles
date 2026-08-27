# pnpm >= 10 links global binaries into $PNPM_HOME/bin and exits 1 with "The
# configured global bin directory ... is not in PATH" while that directory is off
# PATH. mitamae runs commands through /bin/sh, which does not read
# config/.zsh/lib/languages.zsh, so every pnpm call below prepends it itself.
# `pnpm ls -g` needs it too: without it the guard exits non-zero and the install
# runs on every provision.
pnpm_env = %(PATH="$HOME/Library/pnpm/bin:$PATH")

execute "#{pnpm_env} pnpm i -g commitizen" do
  not_if "#{pnpm_env} pnpm ls -g --depth=0 | grep commitizen"
end
execute "#{pnpm_env} pnpm i -g git-cz" do
  not_if "#{pnpm_env} pnpm ls -g --depth=0 | grep git-cz"
end
dotfile ".git-cz.json"
execute "#{pnpm_env} pnpm i -g cz-git" do
  not_if "#{pnpm_env} pnpm ls -g --depth=0 | grep cz-git"
end
execute "#{pnpm_env} pnpm i -g czg" do
  not_if "#{pnpm_env} pnpm ls -g --depth=0 | grep czg"
end
dotfile ".czrc" do
  destination "#{ENV['HOME']}/.config"
end
