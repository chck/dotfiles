case node[:platform]
when 'darwin'
  execute 'brew install dust' do
    not_if "which dust"
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# dust replaces du
alias du="dust"
EOF
''' do
  not_if 'grep dust ~/.zsh/lib/aliases.zsh'
end
