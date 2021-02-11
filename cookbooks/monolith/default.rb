execute "cargo install monolith" do
  not_if "which monolith"
end
