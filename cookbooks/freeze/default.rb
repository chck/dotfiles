case node[:platform]
when 'darwin'
  execute 'brew install charmbracelet/tap/freeze' do
    not_if 'which freeze'
  end
else
  raise NotImplementedError
end
