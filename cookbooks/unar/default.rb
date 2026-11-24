case node[:platform]
when 'darwin'
  execute 'brew install unar' do
    not_if 'which unar'
  end
else
  raise NotImplementedError
end
