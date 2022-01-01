package 'vim'
case node[:platform]
when 'darwin'
  execute 'brew install --HEAD tree-sitter luajit neovim' do
    not_if "which nvim"
  end
else
  raise NotImplementedError
end


dotfile '.vim'
dotfile '.vimrc'
if node[:platform] == 'darwin'
  dotfile '.ideavimrc' do
    not_if 'test -f ~/.ideavimrc'
  end
end
dotfile 'init.vim' do
  destination "#{ENV['HOME']}/.config/nvim"
end

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# vim replaces neovim
alias vi="nvim"
alias vim="nvim"
EOF
''' do
  not_if 'grep vi ~/.zsh/lib/aliases.zsh'
end

execute 'curl https://raw.githubusercontent.com/Shougo/dein.vim/master/bin/installer.sh > /tmp/installer.sh && sh /tmp/installer.sh ~/.vim/bundles' do
  not_if 'test -d ~/.vim/bundles/repos/github.com/Shougo/dein.vim'
end

execute "vim -c 'call dein#install() | q!'" do
  not_if 'test -d ~/.vim/bundles/repos/github.com/Shougo/dein.vim'
end

py310_path = "PATH='/usr/local/opt/python@3.10/bin:$PATH'"
execute "#{py310_path} pip3 install pynvim" do
  not_if "#{py310_path} pip3 list | grep pynvim"
end
