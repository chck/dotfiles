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
    not_if 'git lfs'
  end
when 'ubuntu'
  execute ' sudo apt install -y git-lfs' do
    not_if 'git lfs'
  end
else
  raise NotImplementedError
end

case node[:platform]
when 'darwin'
  execute 'brew install gh' do
    not_if 'which gh'
  end
end

