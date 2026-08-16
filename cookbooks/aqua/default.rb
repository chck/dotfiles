case node[:platform]
when 'darwin'
  execute 'brew trust --formula aquaproj/aqua/aqua && brew install aquaproj/aqua/aqua' do
    not_if 'which aqua'
  end
else
  raise NotImplementedError
end
