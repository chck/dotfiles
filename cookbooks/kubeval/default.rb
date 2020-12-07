case node[:platform]
when 'darwin'
  execute 'brew tap instrumenta/instrumenta && brew install kubeval' do
    not_if 'which kubeval'
  end
else
  raise NotImplementedError
end
