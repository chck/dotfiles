# pre-commit itself is declared in config/mise/config.toml and installed by
# cookbooks/mise. Do not add `mise use --global` here: it rewrites the symlinked
# config and surfaces as a diff in this repository.
execute 'mise exec -- pre-commit install' do
  not_if 'test -f .git/hooks/commit-msg'
end
