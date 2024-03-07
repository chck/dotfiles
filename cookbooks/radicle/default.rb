execute 'curl -sSf https://radicle.xyz/install | sh' do
  not_if 'which rad'
end

