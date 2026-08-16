case node[:platform]
when 'darwin'
  execute 'brew trust --formula yusukebe/tap/ax && brew install yusukebe/tap/ax' do
    not_if 'which ax'
  end
else
  raise NotImplementedError
end
