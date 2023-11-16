case node[:platform]
when 'darwin'
  execute 'brew install wget' do
    not_if "which wget"
  end
else
  raise NotImplementedError
end
