case node[:platform]
when 'arch'
  package 'rust'
  package 'cargo'

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
execute 'rustup toolchain install nightly' do
  not_if "rustup toolchain list | grep nightly"
end
cargo 'rustfmt'
case node[:platform]
when 'darwin'
  execute 'brew install openssl' do
    not_if 'test -d /opt/homebrew/opt/openssl@3/'
  end
  cargo 'cargo-edit'
  execute 'ln -s $HOME/.cargo/bin/ /opt/homebrew/opt/rust' do
    not_if 'test -d /opt/homebrew/opt/rust/'
  end
when 'ubuntu'
  execute 'sudo apt install -y pkg-config libssl-dev' do
    not_if "dpkg -l | grep '^ii' | grep pkg-config"
    not_if "dpkg -l | grep '^ii' | grep libssl-dev"
  end
  cargo 'cargo-edit'
  cargo 'bat'
  cargo 'exa'
  cargo 'du-dust'
  cargo 'bottom'
end
cargo 'rust-script'
cargo 'cargo-update'
cargo 'cargo-deps'
cargo 'cargo-benchcmp'
cargo 'cargo-expand'
cargo 'cargo-make'
cargo 'cargo-generate'
cargo 'hexyl'
cargo 'jless'
cargo 'hyperfine'
cargo 'wasm-pack'
cargo 'git-delta'

execute '''cat <<EOF >> ~/.zsh/lib/aliases.zsh
# cargo-script
alias rust="cargo-script"
EOF
''' do
  not_if 'grep cargo-script ~/.zsh/lib/aliases.zsh'
end

