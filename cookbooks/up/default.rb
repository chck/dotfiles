# `up` upgrades every package manager and toolchain on the machine. It lives in
# ~/bin as a script rather than a shell alias so it also resolves in
# non-interactive shells, where the zsh-defer'd aliases never load.
dotfile 'up' do
  source 'bin/up'
  destination "#{ENV['HOME']}/bin"
end
