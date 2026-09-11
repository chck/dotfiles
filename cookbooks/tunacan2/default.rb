case node[:platform]
when 'darwin'
  include_cookbook 'mas'
  # Tunacan 2 is a separate App Store listing from cookbooks/tunacan (id
  # 980577198), not an upgrade of it, so v1 stays installed alongside.
  #
  # Guarded on the mas receipt rather than on /Applications/<App>.app: the
  # bundle name carries a space and is not derivable from the listing, and a
  # wrong path would re-download the app on every apply.
  execute 'mas install 1594063111' do
    not_if 'mas list | grep -qw 1594063111'
  end
else
  raise NotImplementedError
end
