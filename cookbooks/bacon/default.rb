case node[:platform]
when "darwin", "ubuntu"
  execute "cargo install --locked bacon" do
    not_if "which bacon"
  end
else
  raise NotImplementedError
end

