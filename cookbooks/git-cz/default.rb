execute "pnpm i -g git-cz" do
  not_if "pnpm ls -g --depth=0 | grep git-cz"
end
dotfile ".git-cz.json"
