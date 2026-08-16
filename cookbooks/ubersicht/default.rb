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
  # index.jsx picks the window manager at module eval, before the async
  # ~/.simplebarrc load finishes, so the built-in defaults have to be patched too.
  # aerospacePath must be absolute: Übersicht runs commands without
  # /opt/homebrew/bin on PATH, so the stock "$(which aerospace)" expands to
  # nothing and the widget renders "JSON error…".
  simple_bar_settings = "#{widgets_dir}/simple-bar/lib/settings.js"
  execute %Q[sed -i '' -e 's/windowManager: "yabai"/windowManager: "aerospace"/' -e 's|aerospacePath: "$(which aerospace)"|aerospacePath: "/opt/homebrew/bin/aerospace"|' "#{simple_bar_settings}"] do
    not_if %Q[grep -q 'aerospacePath: "/opt/homebrew/bin/aerospace"' "#{simple_bar_settings}"]
  end
  # simple-bar rewrites this file whenever settings change in its UI
  dotfile '.simplebarrc' do
    source 'simplebarrc.json'
  end
else
  raise NotImplementedError
end
