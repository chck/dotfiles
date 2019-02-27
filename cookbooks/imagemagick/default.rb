case node[:platform]
when 'darwin'
  execute 'brew install imagemagick' do
    not_if 'which convert'
  end
else
  raise NotImplementedError
end
