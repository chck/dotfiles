case node[:platform]
when 'darwin'
  execute 'brew install bazel' do
    not_if 'which bazel'
  end
else
  raise NotImplementedError
end
