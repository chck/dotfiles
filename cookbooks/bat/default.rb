execute "cargo install bat" do
  not_if "which bat"
end
