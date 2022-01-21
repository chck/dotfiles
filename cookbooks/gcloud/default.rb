case node[:platform]
when 'darwin'
  execute 'brew install --cask google-cloud-sdk' do
    not_if 'which gcloud'
  end
when 'ubuntu'
  execute 'sudo apt install -y apt-transport-https ca-certificates gnupg && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && sudo apt update -y && sudo apt install -y google-cloud-sdk' do
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
