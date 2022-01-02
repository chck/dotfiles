case node[:platform]
when 'darwin'
  execute 'brew install lazydocker' do
    not_if 'which lazydocker'
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# lazydocker
alias lzd="lazydocker"
EOF
''' do
  not_if 'grep lazydocker ~/.zsh/lib/aliases.zsh'
end
