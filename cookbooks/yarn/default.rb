case node[:platform]
when 'darwin'
  execute 'curl -o- -L https://yarnpkg.com/install.sh | bash' do
    not_if 'which yarn'
  end
when 'ubuntu'
  execute 'curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && sudo apt update -y && sudo apt install -y yarn' do
    not_if 'which yarn'
  end
else
  raise NotImplementedError
end
