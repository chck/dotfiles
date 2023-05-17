case node[:platform]
when 'darwin'
  execute 'brew install peco' do
    not_if "which peco"
  end
else
  raise NotImplementedError
end
