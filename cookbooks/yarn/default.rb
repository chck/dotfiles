case node[:platform]
when 'darwin'
  execute 'curl -o- -L https://yarnpkg.com/install.sh | bash' do
    not_if 'which yarn'
  end
else
  raise NotImplementedError
end
