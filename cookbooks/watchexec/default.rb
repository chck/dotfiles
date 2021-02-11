execute "cargo install watchexec" do
  not_if "which watchexec"
end
