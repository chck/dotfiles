package 'git'

dotfile '.gitconfig' do
  not_if 'test -f ~/.gitconfig'
end
dotfile '.gitignore_global' do
  not_if 'test -f ~/.gitignore_global'
end

case node[:platform]
when 'darwin'
  execute 'brew install git-lfs' do
    not_if `git lfs version`.include?("darwin")
  end
else
  raise NotImplementedError
end
