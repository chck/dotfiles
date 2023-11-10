case node[:platform]
when 'darwin'
  execute 'brew install azure-cli' do
    not_if 'which az'
  end
else
  raise notimplementederror
end
