case node[:platform]
when 'darwin'
  execute 'brew install watch' do
    not_if 'which watch'
  end
when 'ubuntu'
  # ubuntu already has watch command.
else
  raise NotImplementedError
end
