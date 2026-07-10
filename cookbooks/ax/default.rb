case node[:platform]
when 'darwin'
  execute 'brew install yusukebe/tap/ax' do
    not_if 'which ax'
  end
else
  raise NotImplementedError
end
