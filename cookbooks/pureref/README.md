# PureRef

`./install.sh` installs the latest stable macOS version from the official website
for **personal, non-commercial use**, with a contribution of zero. PureRef is not
available through Homebrew or the Mac App Store.

On first installation, run from an interactive terminal. The installer asks for
agreement to the [PureRef license](https://www.pureref.com/license.php), downloads
the DMG, verifies the app signature and macOS assessment, and copies it to
`/Applications/PureRef.app`. Existing installations are skipped, including on
subsequent applies; this recipe does not upgrade them.

For commercial use, obtain the appropriate license and install PureRef yourself
before running the role. This recipe does not purchase or manage licenses.

The official website issues expiring download links. No download keys are stored
in dotfiles. If its page format changes, the installer stops with an error; update
the extraction or use the [official download page](https://www.pureref.com/download.php).
