case node[:platform]
when 'darwin'
  execute 'brew install direnv' do
    not_if 'which direnv'
  end
when 'ubuntu'
  execute 'sudo apt install -y direnv' do
    not_if 'which direnv'
  end
  execute '''cat <<EOF >> ~/.zsh/lib/apps.zsh
# direnv
export EDITOR=vim
eval "$(direnv hook zsh)"
EOF
''' do
    not_if 'grep direnv ~/.zsh/lib/apps.zsh'
  end
else
  raise NotImplementedError
end
