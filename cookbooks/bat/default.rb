execute "cargo install bat" do
  not_if "which bat"
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# bat
alias cat="bat"
EOF
''' do
  not_if 'grep bat ~/.zsh/lib/aliases.zsh'
end
