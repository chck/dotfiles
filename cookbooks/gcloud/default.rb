case node[:platform]
when 'darwin'
  execute 'brew install --cask google-cloud-sdk' do
    not_if "which gcloud"
  end
else
  raise NotImplementedError
end

github_binary "cloud_sql_proxy" do
  raw_url "https://storage.googleapis.com/cloudsql-proxy/v1.27.1/cloud_sql_proxy.darwin.amd64"
  not_if "which cloud_sql_proxy"
end
