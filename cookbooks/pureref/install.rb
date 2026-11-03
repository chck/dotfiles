require 'fileutils'
require 'open3'
require 'tmpdir'
require 'uri'

# PureRef has no Homebrew cask. Its personal-use download issues expiring links;
# resolve them from the official page instead of saving a download key here.
destination = '/Applications/PureRef.app'
exit if File.directory?(destination)
abort "#{destination} already exists; inspect it before installing PureRef." if File.exist?(destination)

begin
  File.open('/dev/tty', 'r+') do |tty|
    tty.puts 'PureRef will be installed for personal, non-commercial use (free).'
    tty.puts 'Read the license: https://www.pureref.com/license.php'
    tty.print 'Do you agree to the license and want to install? [y/N] '
    tty.flush
    abort 'PureRef installation canceled.' unless tty.gets.to_s.strip.match?(/\Ay(es)?\z/i)
  end
rescue Errno::ENXIO, Errno::ENODEV, Errno::ENOENT
  abort 'PureRef needs license confirmation. Run ./install.sh from an interactive terminal.'
end

temporary_directory = Dir.mktmpdir('pureref-')
mountpoint = File.join(temporary_directory, 'mount')
mounted = false

begin
  # --all avoids silently truncating the inline script containing the metadata.
  scripts, status = Open3.capture2('ax', 'https://www.pureref.com/download.php',
                                  'script:not([src])', '--text', '--all', '--budget', '50000')
  abort 'Cannot fetch PureRef download metadata. Retry or use https://www.pureref.com/download.php' unless status.success?
  metadata = scripts.match(/\},\s*"([\d.]+)",\s*"([^"]+)"\s*,\s*\[/)
  abort 'PureRef download metadata changed. Update this installer or download from the official site.' unless metadata

  version, download_key = metadata.captures
  query = URI.encode_www_form(build: 'OSX64.dmg', version: version,
                             downloadKey: URI.decode_www_form_component(download_key))
  page, status = Open3.capture2('ax', "https://www.pureref.com/freedownload.php?#{query}",
                               'script:not([src])', '--text', '--all', '--budget', '50000')
  abort 'Cannot fetch the PureRef download page. Retry the installation.' unless status.success?
  link = page[/src="(files\/build\.php\?[^"]+)"/, 1]
  abort 'PureRef did not issue an installer link. Retry or download from the official site.' unless link

  # Keep the request on the vendor origin even if the page format changes.
  uri = URI.parse("https://www.pureref.com/#{link}")
  abort 'Unexpected PureRef installer URL. Inspect the official download page.' unless uri.host == 'www.pureref.com' && uri.path == '/files/build.php'
  image = File.join(temporary_directory, 'PureRef.dmg')
  _report, status = Open3.capture2('ax', uri.to_s, '-f', '-o', image,
                                  '--max-bytes', '200000000', '-m', '120')
  abort 'PureRef download failed. Check connectivity and retry.' unless status.success?

  # Only send acceptance after the user has explicitly confirmed above.
  _output, status = Open3.capture2e('hdiutil', 'attach', '-readonly', '-nobrowse',
                                   '-mountpoint', mountpoint, image, stdin_data: "Y\n")
  abort 'Cannot mount the PureRef DMG. Inspect the download and retry.' unless status.success?
  mounted = true
  application = File.join(mountpoint, 'PureRef.app')
  abort 'The DMG has no PureRef.app. Inspect the official download.' unless File.directory?(application)
  abort 'PureRef signature verification failed. Do not install this download.' unless system('codesign', '--verify', '--deep', '--strict', application)
  abort 'macOS rejected PureRef. Check its signature and notarization before installing.' unless system('spctl', '--assess', '--type', 'execute', application)
  # Stage on the destination filesystem so a failed copy cannot leave a partial
  # PureRef.app that the next apply mistakes for a completed installation.
  Dir.mktmpdir('.pureref-', '/Applications') do |staging_directory|
    staged_application = File.join(staging_directory, 'PureRef.app')
    abort 'Cannot copy PureRef to /Applications. Check directory permissions and retry.' unless system('ditto', application, staged_application)
    abort "#{destination} appeared during installation. Inspect it before retrying." if File.exist?(destination)
    File.rename(staged_application, destination)
  end
  puts "Installed PureRef #{version} at #{destination}"
ensure
  if mounted && !system('hdiutil', 'detach', mountpoint)
    warn "Cannot eject PureRef. Eject #{mountpoint} manually; temporary files remain at #{temporary_directory}."
  else
    FileUtils.remove_entry(temporary_directory)
  end
end
