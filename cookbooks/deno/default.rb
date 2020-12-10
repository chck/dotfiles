case node[:platform]
when 'darwin'
  execute 'brew install deno' do
    not_if 'which deno'
  end
else
  raise NotImplementedError
end
