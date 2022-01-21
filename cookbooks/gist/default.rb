case node[:platform]
when 'darwin'
  execute 'brew install gist' do
    not_if 'which gist'
  end
when 'ubuntu'
  execute 'sudo apt install -y gist' do
    not_if 'which gist-paste'
  end
else
  raise NotImplementedError
end
