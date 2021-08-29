execute "cargo install evcxr_repl" do
  not_if "which evcxr"
end
