case node[:platform]
when 'darwin'
  execute 'brew install --cask macfuse' do
    not_if 'which sshfs'
  end
else
  raise NotImplementedError
end
