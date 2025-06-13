case node[:platform]
when 'darwin'
  execute 'brew install ghq' do
    not_if 'which ghq'
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/apps.zsh
# ghq
export GHQ_ROOT=~/Works
EOF
''' do
  not_if 'grep GHQ_ROOT ~/.zsh/lib/apps.zsh'
end
