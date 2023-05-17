case node[:platform]
when 'darwin'
  execute 'curl -sSL https://install.python-poetry.org | python3 -' do
    not_if 'which poetry'
  end
when 'ubuntu'
  execute 'curl -sSL https://install.python-poetry.org | python3 -' do
    not_if 'which poetry'
  end
else
  raise NotImplementedError
end

case node[:platform]
when 'darwin'
  execute 'poetry completions zsh > $(brew --prefix)/share/zsh/site-functions/_poetry' do
    not_if 'test -f $(brew --prefix)/share/zsh/site-functions/_poetry'
  end
when 'ubuntu'
  execute 'mkdir ~/.zfunc && poetry completions zsh > ~/.zfunc/_poetry' do
    not_if 'test -f ~/.zfunc/_poetry'
  end
end

execute 'poetry config virtualenvs.in-project true' do
  not_if 'poetry config virtualenvs.in-project | grep true'
end
