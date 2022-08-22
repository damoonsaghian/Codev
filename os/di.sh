set -e

case "$1" in
  riscv64) ;;
  arm64) ;;
  armhf) ;;
  amd64) ;;
  i386) ;;
  ppc64el) ;;
  *) echo "\"$1\" architecture is not supported"
    echo "supported architectures are:"
    echo "riscv64 arm64 armhf amd64 i386 ppc64el"
    exit ;;
esac

wget2 -v &> /dev/null && alias wget=wget2

project_path="$(dirname "$0")/.."

mkdir -p "$project_path"/.cache/di
cd "$project_path"/.cache/di

# download and verify latest Debian installation iso
rm -f SHA512SUMS
wget https://cdimage.debian.org/debian-cd/current/"$1"/iso-cd/SHA512SUMS
debian_image="$(printf debian-*-"$1"-netinst.iso)"
wget --continue https://cdimage.debian.org/debian-cd/current/"$1"/iso-cd/"$debian_image" 2> /dev/null || true
if [ -f "$debian_image" ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  true
else
  rm -f debian-*-"$1"-netinst.iso
  wget --recursive --level=1 --no-directories \
    --accept "debian-*-$1-netinst.iso" --reject "debian-*-*-$1-netinst.iso" \
    https://cdimage.debian.org/debian-cd/current/"$1"/iso-cd/
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded installation image failed; try again"
    exit 1
  }
  debian_image="$(printf debian-*-"$1"-netinst.iso)"
fi

# download and extract firmware archive
rm -f SHA512SUMS
wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/SHA512SUMS
if [ -f firmware.tar.gz ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  true
else
  rm -f firmware.tar.gz
  wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/firmware.tar.gz
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded firmware archive failed; try again"
    exit 1
  }
fi
rm -rf firmware
mkdir firmware
cd firmware
tar -xzf ../firmware.tar.gz
cd "$project_path"/.cache/di

# extract "initrd.gz" from the iso file
rm -rf install*
xorriso -osirrox on -indev "$debian_image" -extract_l / ./ '/install*/initrd.gz'
xorriso -osirrox on -indev "$debian_image" -extract_l / ./ '/install*/gtk/initrd.gz'
initrd_rpath="$(printf install*/initrd.gz)"
initrd_gtk_rpath="$(printf install*/gtk/initrd.gz)"

# add "preseed.cfg" to "initrd.gz", and force Debian installer to use text frontend
rm -rf initrd
mkdir -p initrd
cd "$project_path"/.cache/di/initrd
bsdcat ../"$initrd_rpath" | bsdcpio -i
cp "$project_path"/os/di-preseed.cfg .
echo 'export DEBIAN_FRONTEND=text' > lib/debian-installer.d/S99text-frontend
rm -f "$project_path"/.cache/di/"$initrd_rpath"
find . | bsdcpio -oz --format=newc > "$project_path"/.cache/di/"$initrd_rpath"
rm -rf ./*
# do the same for "gtk/initrd.gz"
bsdcat ../"$initrd_gtk_rpath" | bsdcpio -i
cp "$project_path"/os/di-preseed.cfg .
echo 'export DEBIAN_FRONTEND=text' > lib/debian-installer.d/S99text-frontend
rm -f "$project_path"/.cache/di/"$initrd_gtk_rpath"
find . | bsdcpio -oz --format=newc > "$project_path"/.cache/di/"$initrd_gtk_rpath"
cd "$project_path"/.cache/di
rm -rf initrd

# prepend the microcode to initrd
# https://docs.kernel.org/x86/microcode.html#early-load-microcode

# regenerate "md5sum.txt" file
rm -f md5sum.txt
xorriso -osirrox on -indev "$debian_image" -cpx /md5sum.txt md5sum.txt
# remove the lines corresponding to the initrd files
grep -v "initrd.gz" md5sum.txt > tmpfile && mv tmpfile md5sum.txt
# add the md5sum of the new initrd files
md5sum ./"$initrd_rpath" ./"$initrd_gtk_rpath" >> md5sum.txt

mkdir partman-recepies
echo -n 'default ::
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
  format{ } .
' > partman-recepies/default
echo -n 'bios ::
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
	format{ } .
' > partman-recepies/bios
echo -n 'ppc ::
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
  format{ } .
' > partman-recepies/ppc

# generate the modified iso file
[ -f debian-modified-"$1"-netinst.iso ] && rm -f debian-modified-"$1"-netinst.iso
xorriso -indev "$debian_image" -outdev debian-modified-"$1"-netinst.iso \
  -overwrite on -pathspecs off -cd / \
  -add firmware "$initrd_rpath" "$initrd_gtk_rpath" md5sum.txt \
  -map partman-recepies/ '/comshell/partman-recepies/' \
  -map "$project_path"/os/ '/comshell/os/' \
  -map "$project_path"/comshell-py/ '/comshell/comshell-py/'

sh "$project_path"/deb/sd.sh write debian-modified-"$1"-netinst.iso "$2"
echo 'Debian installation media created successfully'
