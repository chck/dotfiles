case node[:platform]
when 'ubuntu'
  execute 'sudo apt install -y guake' do
    not_if 'which guake'
  end
else
  raise NotImplementedError
end
