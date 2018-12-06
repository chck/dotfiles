package 'mecab'
package 'mecab-ipadic'
package 'xz' # mecab dependencies

git "install mecab-ipadic-neologd" do
  repository "https://github.com/neologd/mecab-ipadic-neologd.git"
  depth 1
  destination "/tmp/neologd"
end

directory "/usr/local/lib/mecab/dic" do
  owner node[:user]
end

execute "/tmp/neologd/bin/install-mecab-ipadic-neologd -n -u -y && rm -rf /tmp/neologd"
dotfile 'mecabrc' do
  destination '/usr/local/etc'
end
