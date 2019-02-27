case node[:platform]
when 'darwin'
  execute 'brew install unrar' do
    not_if 'which unrar'
  end
else
  raise NotImplementedError
end
