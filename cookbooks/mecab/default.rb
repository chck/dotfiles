case node[:platform]
when 'darwin'
  package 'mecab'
  package 'mecab-ipadic'
when 'ubuntu'
  execute 'sudo apt install -y mecab libmecab-dev mecab-ipadic-utf8' do
    not_if 'which mecab'
  end
end
