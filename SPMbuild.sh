pkg=codev-util

spm_import gnunet

# doas rules for sd.sh

pkg=codev-shell

spm_import zsh
spm_import qt
spm_import quickshell
spm_import codev

pkg=codev

spm_import qt
spm_import quickshell # needed for Process qml type
spm_import codev-util
spm_import curl
spm_import mauikit-filebrowsing
spm_import archive

spm_xcript inst/app codev

ln "$pkg_dir/.data/codev.svg" "$pkg_dir/.cache/spm/$ARCH/app/codev.svg"
