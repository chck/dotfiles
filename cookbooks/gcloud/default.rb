#github_binary 'google-cloud-sdk' do
#  repository 'google-cloud-sdk/google-cloud-sdk'
#  version 'v213.0.0'
#  binary_path 'google-cloud-sdk-213.0.0'
#end

#execute '/usr/local/bin/google-cloud-sdk/install.sh --quiet'

execute 'sh -c "$(curl -fsSL https://sdk.cloud.google.com)"'
