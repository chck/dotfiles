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

case `uname -m`
when 'x86_64'
  platform = `uname`.lower
  github_binary "cloud_sql_proxy" do
    raw_url "https://storage.googleapis.com/cloudsql-proxy/v1.28.0/cloud_sql_proxy.#{platform}.amd64"
    not_if "which cloud_sql_proxy"
  end
end
