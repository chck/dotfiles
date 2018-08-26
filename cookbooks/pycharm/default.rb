case node[:platform]
when 'darwin'
  execute 'brew cask install pycharm'
else
  raise NotImplementedError
end
