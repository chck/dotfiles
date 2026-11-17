include_cookbook 'rust'

# The terminal client is a standalone Cargo package in the upstream repository;
# it does not need the local engine's Bazel, pnpm or Wrangler build. There is no
# mise/Homebrew/crates.io package or prebuilt GitHub release yet.
execute 'cargo install --git https://github.com/cloudflare/kitesurf.git --locked kitesurf' do
  not_if 'command -v kitesurf'
end
