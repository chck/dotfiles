case node[:platform]
when 'darwin'
  execute 'brew install dotenvx/brew/dotenvx' do
    not_if 'which dotenvx'
  end
else
  raise NotImplementedError
end
