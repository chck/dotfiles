case node[:platform]
when 'darwin'
  execute 'brew install imagemagick'
else
  raise NotImplementedError
end
