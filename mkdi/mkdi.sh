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

apt-get install simple-cdd

# boot parameter DEBIAN_FRONTEND=text

# debian-cd config: FORCE_FIRMWARE=1

# U-Boot distro: /boot/extlinux/extlinux.conf

# preseed.sh
# "$project_path"/os/
# "$project_path"/comshell-py/

sh "$project_path"/os/sd write /dev/"$2" debian-"$1"-netinst.iso
echo 'Debian installation media created successfully'
