case node[:platform]
when 'darwin'
  execute 'brew install bfg' do
    not_if "which bfg"
  end
else
  raise NotImplementedError
end
