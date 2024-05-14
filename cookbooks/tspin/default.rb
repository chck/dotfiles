execute "cargo install tailspin" do
  not_if "which tspin"
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# tspin replaces tail
alias tail="tspin"
EOF
''' do
  not_if 'grep tspin ~/.zsh/lib/aliases.zsh'
end
