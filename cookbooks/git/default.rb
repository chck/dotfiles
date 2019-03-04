package 'git'

dotfile '.gitconfig'
dotfile '.gitignore_global' do
  not_if 'test -f ~/.gitignore_global'
end
