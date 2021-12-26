case node[:platform]
when 'darwin'
  execute 'brew install --cask visual-studio-code' do
    not_if 'which code'
  end
else
  raise NotImplementedError
end
