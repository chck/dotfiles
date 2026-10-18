case node[:platform]
 when 'darwin'
   execute 'brew install --cask --force elgato-wave-link' do
     not_if 'test -d /Applications/Elgato\ Wave\ Link.app'
   end
 else
   raise NotImplementedError
 end
