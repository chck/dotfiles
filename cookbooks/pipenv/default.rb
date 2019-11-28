case node[:platform]
when 'darwin'
  execute 'brew install pipenv' do
    not_if 'which pipenv'
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/languages.zsh
export PIPENV_VENV_IN_PROJECT=true
# https://github.com/pypa/pipenv/issues/1914
export PIPENV_SKIP_LOCK=true
EOF
''' do
  not_if 'grep PIPENV ~/.zsh/lib/languages.zsh'
end
