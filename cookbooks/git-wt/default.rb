case node[:platform]
when 'darwin'
  execute 'brew trust --formula k1LoW/tap/git-wt && brew install k1LoW/tap/git-wt' do
    not_if 'which git-wt'
  end
else
  raise NotImplementedError
end
