case node[:platform]
when 'darwin'
  execute 'curl https://raw.githubusercontent.com/sdispater/poetry/master/get-poetry.py > /tmp/get-poetry.py && python3 /tmp/get-poetry.py -yp' do
    not_if 'which poetry'
  end
else
  raise NotImplementedError
end

execute '''cat <<EOF >> ~/.zsh/lib/languages.zsh
# Python
export PATH=$HOME/.poetry/bin:$PATH
EOF
''' do
  not_if 'grep poetry ~/.zsh/lib/languages.zsh'
end
