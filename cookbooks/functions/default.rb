node.reverse_merge!(
  os: run_command('uname').stdout.strip.downcase,
)

define :dotfile, source: nil, destination: nil do
  destination ||= ENV['HOME']
  source = params[:source] || params[:name]
  link File.join(destination, params[:name]) do
    to File.expand_path("../../../config/#{source}", __FILE__)
    user node[:user]
  end
end

define :github_binary, raw_url: nil, version: nil, repository: nil, archive: nil, binary_path: nil do
  cmd = params[:name]
  bin_path = "/usr/local/bin/#{cmd}"
  archive = params[:archive]
  url = params[:raw_url] || "https://github.com/#{params[:repository]}/releases/download/#{params[:version]}/#{archive}"

  if archive
    if archive.end_with?('.zip')
      extract = "unzip -o"
    elsif archive.end_with?('.tar.gz')
      extract = "tar xvzf"
    else
      raise "unexpected ext archive: #{archive}"
    end

    execute "curl -fSL -o /tmp/#{archive} #{url}" do
      not_if "test -f #{bin_path}"
    end
    execute "#{extract} /tmp/#{archive}" do
      not_if "test -f #{bin_path}"
      cwd "/tmp"
    end
  else
    execute "curl -fSL -o /tmp/#{cmd} #{url}" do
      not_if "test -f #{bin_path}"
    end
  end
  execute "mv /tmp/#{params[:binary_path] || cmd} #{bin_path} && chmod +x #{bin_path}" do
    not_if "test -f #{bin_path}"
  end
end

define :user_service, action: [] do
  name = params[:name]

  Array(params[:action]).each do |action|
    case action
    when :enable
      execute "sudo -E -u #{node[:user]} systemctl --user enable #{name}" do
        not_if "sudo -E -u #{node[:user]} systemctl --user --quiet is-enabled #{name}"
      end
    when :start
      execute "sudo -E -u #{node[:user]} systemctl --user start #{name}" do
        not_if "sudo -E -u #{node[:user]} systemctl --user --quiet is-active #{name}"
      end
    end
  end
end

define :cargo, action: [] do
  name = params[:name]
  execute "cargo +nightly install --force --verbose #{name}" do
    not_if %Q[cargo install --list | grep "^#{name}"]
  end
end
