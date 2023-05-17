execute "cargo install --locked watchexec-cli" do
  not_if "which watchexec"
end
