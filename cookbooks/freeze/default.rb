case node[:platform]
when 'darwin'
  execute 'brew trust --formula charmbracelet/tap/freeze && brew install charmbracelet/tap/freeze' do
    not_if 'which freeze'
  end
else
  raise NotImplementedError
end
