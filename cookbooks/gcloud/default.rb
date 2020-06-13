#github_binary 'google-cloud-sdk' do
#  repository 'google-cloud-sdk/google-cloud-sdk'
#  version 'v213.0.0'
#  binary_path 'google-cloud-sdk-213.0.0'
#end

#execute '/usr/local/bin/google-cloud-sdk/install.sh --quiet'

execute 'sh -c "$(curl -fsSL https://sdk.cloud.google.com)"' do
  not_if "which gcloud"
end

github_binary "cloud_sql_proxy" do
  raw_url "https://storage.googleapis.com/cloudsql-proxy/v1.17/cloud_sql_proxy.darwin.amd64"
  not_if "which cloud_sql_proxy"
end
