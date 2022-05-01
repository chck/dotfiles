case node[:platform]
when 'darwin'
  execute 'brew install awscli' do
    not_if 'which aws'
  end
  execute 'brew install saml2aws' do
    not_if 'which saml2aws'
  end
else
  raise notimplementederror
end
