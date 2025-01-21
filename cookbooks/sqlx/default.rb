case node[:platform]
when 'darwin', 'ubuntu'
  execute 'cargo install sqlx-cli' do
    not_if "which sqlx"
  end
else
  raise NotImplementedError
end
