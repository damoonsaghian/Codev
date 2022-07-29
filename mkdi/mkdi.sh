set -e

# https://github.com/delfer/debian-preseed-iso/blob/master/build.sh

case "$1" in
  riscv64) ;;
  arm64) ;;
  armhf) ;;
  amd64) ;;
  i386) ;;
  ppc64el) ;;
  *) echo "\"$1\" architecture is not supported";
    echo "supported architectures are:";
    echo "riscv64 arm64 armhf amd64 i386 ppc64el";
    exit;;
esac

wget2 -v &> /dev/null && alias wget=wget2

project_path="$(dirname "$0")/.."

mkdir -p "$project_path"/.cache/mkdi && true
cd "$project_path"/.cache/mkdi

# download and verify Debian installation image
rm -f SHA512SUMS && true
wget https://cdimage.debian.org/debian-cd/current/"$1"/iso-cd/SHA512SUMS
debian_image="$(ls debian-*-"$1"-netinst.iso)"
if [ -f "$debian_image" ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  echo "using priviously downloaded installation image"
else
  [ -f "$debian_image" ] && rm -f debian-*-"$1"-netinst.iso && true
  wget --recursive --level=1 --no-directories \
    --accept "debian-*-$1-netinst.iso" --reject "debian-*-*-$1-netinst.iso" \
    https://cdimage.debian.org/debian-cd/current/"$1"/iso-cd/
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded installation image failed; try again"
    exit 1
  }
fi

# extract "initrd.gz" from the iso file
rm -rf install* && true
xorriso -osirrox on -indev "$debian_image" -extract_l / ./ '/install*/initrd.gz'
xorriso -osirrox on -indev "$debian_image" -extract_l / ./ '/install*/gtk/initrd.gz'
rm -rf initrd && true
mkdir -p initrd
cd "$project_path"/.cache/mkdi/initrd

# add "preseed.cfg" to "initrd.gz", and force Debian installer to use text frontend
initrd_path="$(dirname "$project_path"/.cache/mkdi/install*/initrd.gz)"/initrd.gz
bsdcat "$initrd_path" | bsdcpio -i
cp "$project_path"/mkdi/preseed.cfg .
echo 'export DEBIAN_FRONTEND=text' > lib/debian-installer.d/S99text-frontend
rm -f "$initrd_path"
find . | bsdcpio -oz --format=newc > "$initrd_path"
rm -rf ./*
# do the same for "gtk/initrd.gz"
initrd_gtk_path="$(dirname "$project_path"/.cache/mkdi/install*/gtk/initrd.gz)"/initrd.gz
bsdcat "$initrd_gtk_path" | bsdcpio -i
cp "$project_path"/mkdi/preseed.cfg .
echo 'export DEBIAN_FRONTEND=text' > lib/debian-installer.d/S99text-frontend
rm -f "$initrd_gtk_path"
find . | bsdcpio -oz --format=newc > "$initrd_gtk_path"
cd "$project_path"/.cache/mkdi; rm -rf initrd && true

# prepend the microcode to initrd
# https://docs.kernel.org/x86/microcode.html#early-load-microcode

# regenerate "md5sum.txt" file
rm -f md5sum.txt && true
xorriso -osirrox on -indev "$debian_image" -cpx /md5sum.txt md5sum.txt
# remove the lines corresponding to the initrd files
grep -v "initrd.gz" md5sum.txt > tmpfile && mv tmpfile md5sum.txt
# add the md5sum of the new initrd files
md5sum ./install*/initrd.gz ./install*/gtk/initrd.gz >> md5sum.txt

# download and extract firmware archive
rm -f SHA512SUMS && true
wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/SHA512SUMS
if [ -f firmware.tar.gz ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  echo "using priviously downloaded firmware archive"
else
  [ -f firmware.tar.gz ] && rm -f firmware.tar.gz && true
  wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/firmware.tar.gz
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded firmware archive failed; try again"
    exit 1
  }
fi
rm -rf firmware && true
mkdir firmware
cd firmware
tar -xzf "$project_path"/.cache/mkdi/firmware.tar.gz
[ -d firmware ] && { mv firmware/* .; rmdir firmware; }
cd "$project_path"/.cache/mkdi

mkdir partman-recepies && true
echo 'default ::
538 538 1075 free
	$iflabel{ gpt }
	method{ efi }
	format{ } .
900 10000 -1 btrfs
  method{ format }
  format{ }
  use_filesystem{ }
  filesystem{ btrfs }
  mountpoint{ / } .
100% 512 200% linux-swap
  method{ swap }
  format{ } .' > partman-recepies/default
echo 'bios ::
1 1 1 free
	$iflabel{ gpt }
	method{ biosgrub } .
1500 10000 -1 btrfs
	method{ format }
	format{ }
	use_filesystem{ }
	filesystem{ btrfs }
	mountpoint{ / } .
100% 512 200% linux-swap
	method{ swap }
	format{ } .' > partman-recepies/bios
echo 'ppc ::
8 1 1 prep
  $primary{ }
  $bootable{ }
  method{ prep } .
1500 10000 -1 btrfs
  $primary{ }
  method{ format }
  format{ }
  use_filesystem{ }
  filesystem{ btrfs }
  mountpoint{ / } .
100% 512 300% linux-swap
  method{ swap }
  format{ } .' > partman-recepies/ppc

# generate the modified iso file
[ -f debian-modified-"$1"-netinst.iso ] && rm -f debian-modified-"$1"-netinst.iso && true
xorriso -indev "$debian_image" -outdev debian-modified-"$1"-netinst.iso \
  -overwrite on -pathspecs off -cd / \
  -add install*/initrd.gz install*/gtk/initrd.gz md5sum.txt firmware \
  -map partman-recepies/ /comshell/partman-recepies/ \
  -map "$project_path"/mkdi/preseed.sh /comshell/preseed.sh \
  -map "$project_path"/os/ /comshell/os/ \
  -map "$project_path"/comshell-py/ /comshell/comshell-py/

sh "$project_path"/os/sd write /dev/"$2" debian-modified-"$1"-netinst.iso
echo 'Debian installation media created successfully'
