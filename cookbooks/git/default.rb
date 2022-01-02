package 'git'

dotfile '.gitconfig' do
  not_if 'test -f ~/.gitconfig'
end
dotfile '.gitignore_global' do
  not_if 'test -f ~/.gitignore_global'
end
