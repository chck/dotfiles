execute "pnpm i -g commitizen" do
  not_if "pnpm ls -g --depth=0 | grep commitizen"
end
execute "pnpm i -g git-cz" do
  not_if "pnpm ls -g --depth=0 | grep git-cz"
end
dotfile ".git-cz.json"
execute "pnpm i -g cz-git" do
  not_if "pnpm ls -g --depth=0 | grep cz-git"
end
execute 'pnpm i -g czg' do
  not_if "pnpm ls -g --depth=0 | grep czg"
end
dotfile ".czrc" do
  destination "#{ENV['HOME']}/.config"
end
