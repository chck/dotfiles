case node[:platform]
when 'darwin'
  execute 'brew trust --formula quarylabs/quary/sqruff && brew install quarylabs/quary/sqruff' do
    not_if "which sqruff"
  end
else
  raise NotImplementedError
end
