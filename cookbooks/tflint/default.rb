case node[:platform]
when 'darwin'
  execute 'brew install tflint' do
    not_if "which tflint"
  end
else
  raise NotImplementedError
end

