case node[:platform]
when 'darwin'
  execute 'brew cask install visual-studio-code' do
    not_if 'which code'
  end
else
  raise NotImplementedError
end
