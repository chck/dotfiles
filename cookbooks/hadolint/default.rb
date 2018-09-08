case node[:platform]
when 'darwin'
  execute 'brew install hadolint'
else
  raise NotImplementedError
end
