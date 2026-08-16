widgets_dir = "#{ENV['HOME']}/Library/Application Support/Übersicht/widgets"

case node[:platform]
when 'darwin'
  execute 'brew install --cask ubersicht' do
    not_if 'test -d /Applications/Übersicht.app/'
  end
  execute %Q[mkdir -p "#{widgets_dir}"] do
    not_if %Q[test -d "#{widgets_dir}"]
  end
  # simple-bar self-updates via git pull, so it is cloned rather than tracked here
  execute %Q[git clone --depth 1 https://github.com/Jean-Tinland/simple-bar "#{widgets_dir}/simple-bar"] do
    not_if %Q[test -d "#{widgets_dir}/simple-bar"]
  end
else
  raise NotImplementedError
end
