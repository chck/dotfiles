case node[:platform]
when 'darwin'
  execute 'brew install fzf' do
    not_if "which fzf"
  end
else
  raise NotImplementedError
end
