case node[:platform]
when 'darwin'
  execute 'brew install bat' do
    not_if "which bat"
  end
when 'ubuntu'
  execute 'sudo apt install -y bat' do
    not_if "which bat"
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# bat replaces cat
alias cat="bat"
EOF
''' do
  not_if 'grep bat ~/.zsh/lib/aliases.zsh'
end
