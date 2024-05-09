case node[:platform]
when 'darwin'
  execute 'brew install eza' do
    not_if 'which eza'
  end
when 'ubuntu'
  execute 'cargo install eza' do
    not_if "which eza"
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# eza replaces ls
alias ls="eza -a"
EOF
''' do
  not_if 'grep eza ~/.zsh/lib/aliases.zsh'
end
