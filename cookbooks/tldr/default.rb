case node[:platform]
when 'darwin'
  # the `tldr` formula was disabled 2025-10-24; tlrc is the official client and
  # still provides the `tldr` command
  execute 'brew install tlrc' do
    not_if 'which tldr'
  end
when 'ubuntu'
  execute 'sudo apt install -y tldr' do
    not_if 'which tldr'
  end
else
  raise NotImplementedError
end
