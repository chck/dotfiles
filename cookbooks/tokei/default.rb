execute "cargo install tokei" do
  not_if "which tokei"
end
