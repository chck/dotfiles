case node[:platform]
when 'darwin'
  execute 'brew install awscli' do
    not_if 'which aws'
  end
  execute 'brew install saml2aws' do
    not_if 'which saml2aws'
  end
when 'ubuntu'
  execute 'sudo apt install -y awscli' do
    not_if 'which aws'
  end
  execute 'CURRENT_VERSION=$(curl -Ls https://api.github.com/repos/Versent/saml2aws/releases/latest | grep "tag_name" | cut -d"v" -f2 | cut -d"\"" -f1) && wget -c "https://github.com/Versent/saml2aws/releases/download/v${CURRENT_VERSION}/saml2aws_${CURRENT_VERSION}_linux_amd64.tar.gz" -O - | tar -xzv -C ~/.local/bin' do
    not_if 'which saml2aws'
  end
else
  raise notimplementederror
end
