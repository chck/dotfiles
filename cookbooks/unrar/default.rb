case node[:platform]
when 'darwin'
  execute 'brew trust --formula carlocab/personal/unrar && brew install carlocab/personal/unrar' do
    not_if 'which unrar'
  end
else
  raise NotImplementedError
end
