case node[:platform]
when 'darwin'
  execute 'brew install httpie' do
    not_if "which http"
  end
when 'ubuntu'
  execute '''curl -SsL https://packages.httpie.io/deb/KEY.gpg | sudo apt-key add - && \
  sudo curl -SsL -o /etc/apt/sources.list.d/httpie.list https://packages.httpie.io/deb/httpie.list && \
  sudo apt update && \
  sudo apt install -y httpie &&
  ''' do
    not_if "which http"
  end
else
  raise NotImplementedError
end

