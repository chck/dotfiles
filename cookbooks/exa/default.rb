case node[:platform]
when 'darwin'
  execute 'brew install exa' do
    not_if 'which exa'
  end
when 'ubuntu'
  execute 'sudo apt install exa' do
    not_if "which exa"
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# exa replaces ls
alias ls="exa -a"
EOF
''' do
  not_if 'grep exa ~/.zsh/lib/aliases.zsh'
end
