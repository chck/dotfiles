case node[:platform]
when 'darwin'
  execute 'brew install --cask brave-browser' do
    not_if 'test -d /Applications/Brave\ Browser.app/'
  end
when 'ubuntu'
  execute '''
sudo apt install apt-transport-https curl \
&& sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
&& echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list \
&& sudo apt update -y \
&& sudo apt install -y brave-browser
''' do
    not_if 'which brave-browser'
  end
else
  raise NotImplementedError
end
