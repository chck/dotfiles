case node[:platform]
when 'darwin'
  execute 'mise use --global pre-commit@latest' do
    not_if 'mise which pre-commit'
  end
else
  raise NotImplementedError
end

execute 'mise exec -- pre-commit install' do
  not_if 'test -f .git/hooks/commit-msg'
end
