case node[:platform]
when 'darwin'
  execute 'brew install unrar'
else
  raise NotImplementedError
end
