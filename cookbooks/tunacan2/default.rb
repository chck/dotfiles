case node[:platform]
when 'darwin'
  include_cookbook 'mas'
  # Guarded on the mas receipt rather than on /Applications/<App>.app: the
  # bundle is Tunacan2.app while the listing says "Tunacan 2", and a wrong path
  # would re-download the app on every apply.
  #
  # `mas get`, not `mas install`: install only re-downloads an app this Apple
  # Account has already acquired. See the add-cookbook skill for the rest.
  execute 'mas get 1594063111' do
    not_if 'mas list | grep -qw 1594063111'
  end
else
  raise NotImplementedError
end
