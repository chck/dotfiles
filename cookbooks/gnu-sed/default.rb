case node[:platform]
when 'darwin'
  execute 'brew install gnu-sed' do
    not_if 'which gsed'
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh

# GNU sed
alias sed=gsed
EOF
''' do
  not_if 'grep gsed ~/.zsh/lib/aliases.zsh'
end
