execute "cargo install pastel" do
  not_if "which pastel"
end
