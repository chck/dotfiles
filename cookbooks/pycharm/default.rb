case node[:platform]
when 'darwin'
  execute 'brew install --cask pycharm' do
    not_if 'test -d /Applications/PyCharm.app/'
  end
else
  raise NotImplementedError
end
