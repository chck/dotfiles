case node[:platform]
when 'darwin'
  execute 'brew install terraform' do
    not_if 'which terraform'
  end
when 'ubuntu'
  execute 'curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add - && sudo apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && sudo apt install -y terraform
' do
    not_if 'which terraform'
  end
else
  raise NotImplementedError
end
