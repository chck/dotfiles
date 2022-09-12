case node[:platform]
when 'darwin'
  execute 'brew install bottom' do
    not_if "which btm"
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# bottom replaces top
alias top="btm"
EOF
''' do
  not_if 'grep btm ~/.zsh/lib/aliases.zsh'
end
