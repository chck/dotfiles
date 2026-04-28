case node[:platform]
when 'darwin'
  execute 'brew install --cask android-platform-tools' do
    not_if 'which adb'
  end

  execute 'brew install scrcpy' do
    not_if 'which scrcpy'
  end
else
  raise NotImplementedError
end
