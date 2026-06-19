case node[:platform]
when 'darwin'
  execute 'brew install --cask google-cloud-sdk' do
    not_if 'which gcloud'
  end
when 'ubuntu'
  execute 'curl https://sdk.cloud.google.com | bash' do
    not_if 'which gcloud'
  end
else
  raise NotImplementedError
end

execute 'brew install cloud-sql-proxy' do
  not_if 'which cloud-sql-proxy'
end
