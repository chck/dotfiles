case node[:platform]
when 'darwin'
  execute 'curl https://mise.run | sh' do
    not_if 'which mise'
  end
else
  raise NotImplementedError
end

