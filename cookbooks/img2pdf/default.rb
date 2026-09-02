case node[:platform]
when 'darwin'
  execute 'brew install img2pdf' do
    not_if 'which img2pdf'
  end
else
  raise NotImplementedError
end
