execute "cargo install htmlq" do
  not_if "which htmlq"
end
