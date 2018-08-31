case node[:platform]
when 'darwin'
  execute 'brew tap tldr-pages/tldr && brew install tldr'
else
  raise NotImplementedError
end
