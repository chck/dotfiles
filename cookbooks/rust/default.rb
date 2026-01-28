case node[:platform]
when 'arch'
  include_cookbook 'yaourt'
  yaourt 'rust-src'
else
  local_ruby_block 'install rust' do
    rustc_path = "#{ENV['HOME']}/.cargo/bin/rustc"

    block do
      system("curl https://sh.rustup.rs -sSf | sh")

      until File.exist?(rustc_path)
        sleep 1
      end
    end
    not_if "test -f #{rustc_path}"
  end
  execute 'rustup component add rust-src' do
    not_if 'rustup component list --installed | grep rust-src'
  end
end

unless ENV['PATH'].include?("#{ENV['HOME']}/.cargo/bin:")
  MItamae.logger.info('Prepending ~/.cargo/bin to PATH during this execution')
  ENV['PATH'] = "#{ENV['HOME']}/.cargo/bin:#{ENV['PATH']}"
end

package 'cmake'
cargo 'rustfmt'
case node[:platform]
when 'darwin'
  execute 'brew install openssl' do
    not_if 'test -d /opt/homebrew/opt/openssl/'
  end
  cargo 'cargo-edit'
when 'ubuntu'
  execute 'sudo apt install -y pkg-config libssl-dev' do
    not_if "dpkg -l | grep '^ii' | grep pkg-config"
    not_if "dpkg -l | grep '^ii' | grep libssl-dev"
  end
  cargo 'cargo-edit'
  cargo 'bat'
  cargo 'du-dust'
  cargo 'bottom'
end
cargo 'rust-script'
execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# rust-script
alias rust="rust-script"
EOF
''' do
  not_if 'grep rust-script ~/.zsh/lib/aliases.zsh'
end
cargo 'cargo-update'
cargo 'cargo-binstall'
cargo 'cargo-deps'
cargo 'cargo-benchcmp'
cargo 'cargo-expand'
cargo 'cargo-make'
cargo 'cargo-machete'
cargo 'cargo-features-manager'
cargo 'cargo-generate'
cargo 'cargo-wizard'
cargo 'hexyl'
cargo 'jless'
cargo 'hyperfine'
cargo 'wasm-pack'
cargo 'git-delta'
cargo 'rust-stakeholder' do
  git_url "https://github.com/giacomo-b/rust-stakeholder.git"
end
execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# rust-stakeholder
alias sl="rust-stakeholder --dev-type data-science --jargon high"
EOF
''' do
  not_if 'grep rust-stakeholder ~/.zsh/lib/aliases.zsh'
end

