package 'mecab'
package 'mecab-ipadic'
package 'xz' # mecab dependencies

git "install mecab-ipadic-neologd" do
  not_if 'which mecab'
  repository "https://github.com/neologd/mecab-ipadic-neologd.git"
  depth 1
  destination "/tmp/neologd"
end

directory "/usr/local/lib/mecab/dic" do
  owner node[:user]
end

execute "/tmp/neologd/bin/install-mecab-ipadic-neologd -n -u -y && rm -rf /tmp/neologd" do
  not_if 'test -d /usr/local/lib/mecab/dic/mecab-ipadic-neologd/'
end
dotfile 'mecabrc' do
  destination '/usr/local/etc'
end
