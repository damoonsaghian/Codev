set -e

case "$1" in
  riscv64) ;;
  arm64) ;;
  armhf) ;;
  armel) ;;
  amd64) ;;
  i386) ;;
  ppc64el) ;;
  *) echo "the \"$1\" architecture is not supported";
    echo "supported architectures are:";
    echo "riscv64 arm64 armhf armel amd64 i386 ppc64el";
    exit;;
esac

wget2 -v && alias wget=wget2

project_path="$(dirname "$0")/.."

mkdir -p "$project_path"/.cache/mkdi && true
cd "$project_path"/.cache/mkdi

mkdir profiles && true
cp "$project_path"/mkdi/preseed.cfg profiles/comshell.preseed

echo "#!/bin/sh
project_path=\"$project_path\"" > copy-files.sh
echo '
mkdir "$CDDIR"/comshell
cp "$project_path"/mkdi/preseed.sh "$CDDIR"/comshell/
cp -r "$project_path"/os "$CDDIR"/comshell/
cp -r "$project_path"/comshell-py "$CDDIR"/comshell/
# U-Boot distro:
mkdir -p "$CDDIR"/boot/extlinux
echo '' > "$CDDIR"/boot/extlinux/extlinux.conf' >> copy-files.sh

echo "export KERNEL_PARAMS=\"DEBIAN_FRONTEND=text\"
# debian-cd option
export DISC_START_HOOK=\"$project_path/.cache/mkdir/copy-files.sh\"
export FORCE_FIRMWARE=1" > profiles/comshell.conf

sudo apt-get install simple-cdd
simple-cdd --locale en_US --keyboard us --dist stable --profiles comshell

sh "$project_path"/os/sd write /dev/"$2" debian-"$1"-netinst.iso
echo 'Debian installation media created successfully'
