case node[:platform]
when 'darwin'
  execute 'brew install pngpaste' do
    not_if 'which pngpaste'
  end
else
  raise NotImplementedError
end
