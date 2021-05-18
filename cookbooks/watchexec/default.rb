execute "cargo install watchexec-cli" do
  not_if "which watchexec"
end
