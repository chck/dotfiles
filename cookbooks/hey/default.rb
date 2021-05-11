case node[:platform]
when 'darwin'
  execute 'brew install hey' do
    not_if 'which hey'
  end
else
  raise NotImplementedError
end
