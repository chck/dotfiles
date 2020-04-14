execute "cargo install procs" do
  not_if "which procs"
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# procs
alias ps="procs"
EOF
''' do
  not_if 'grep procs ~/.zsh/lib/aliases.zsh'
end
