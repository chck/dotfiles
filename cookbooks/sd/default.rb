execute "cargo install sd" do
  not_if "which sd"
end
