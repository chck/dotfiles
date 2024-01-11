case node[:platform]
when 'darwin'
  execute 'brew install difftastic' do
    not_if "which difft"
  end
else
  raise NotImplementedError
end
