case node[:platform]
when 'darwin'
  # bglgwyng/zat: code outline viewer. Not in the mise registry or homebrew/core,
  # so it comes from the author's tap. `cargo install zat` would install an
  # unrelated crate of the same name (Axlefublr/zat).
  execute 'brew tap bglgwyng/tap' do
    not_if 'brew tap | grep -q bglgwyng/tap'
  end
  execute 'brew install bglgwyng/tap/zat' do
    not_if 'which zat'
  end
else
  raise NotImplementedError
end
