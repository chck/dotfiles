case node[:platform]
when 'darwin'
  execute 'brew install direnv' do
    not_if 'which direnv'
  end
when 'ubuntu'
  execute 'curl -sfL https://direnv.net/install.sh | bash' do
    not_if 'which direnv'
  end
else
  raise NotImplementedError
end
