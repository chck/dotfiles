case node[:platform]
when 'darwin'
  execute 'brew install deno' do
    not_if 'which deno'
  end
else
  raise NotImplementedError
end

# https://www.secondstate.io/articles/ssvmup/
execute 'curl https://raw.githubusercontent.com/second-state/ssvmup/master/installer/init.sh -sSf | sh' do
  not_if 'which ssvmup'
end
