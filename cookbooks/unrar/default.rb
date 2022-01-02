case node[:platform]
when 'darwin'
  execute 'brew install carlocab/personal/unrar' do
    not_if 'which unrar'
  end
else
  raise NotImplementedError
end
