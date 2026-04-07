case node[:platform]
when 'darwin'
  execute 'brew install gemini-cli' do
    not_if 'which gemini'
  end
else
  raise NotImplementedError
end
