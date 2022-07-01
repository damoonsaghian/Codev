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

# download and verify Debian installation image
rm SHA512SUMS && true
wget https://cdimage.debian.org/debian-cd/current/"$1"/iso-cd/SHA512SUMS
debian_image="$(ls debian-*-"$1"-netinst.iso)"
if [ -f "$debian_image" ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  echo "using priviously downloaded installation image"
else
  [ -f "$debian_image" ] && rm debian-*-"$1"-netinst.iso
  wget --recursive --level=1 --no-directories \
    --accept "debian-*-$1-netinst.iso" --reject "debian-*-*-$1-netinst.iso" \
    https://cdimage.debian.org/debian-cd/current/"$1"/iso-cd/
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded installation image failed; try again"
    exit 1
  }
fi

# extract "initrd.gz" from the iso file
rm -r install* && true
xorriso -osirrox on -indev "$debian_image" -extract_l / ./ '/install*/initrd.gz'
xorriso -osirrox on -indev "$debian_image" -extract_l / ./ '/install*/gtk/initrd.gz'
rm -r initrd && true
mkdir -p initrd
cd "$project_path"/.cache/mkdi/initrd

# add "preseed.cfg" to "initrd.gz", and force Debian installer to use text frontend
initrd_path="$(dirname "$project_path"/.cache/mkdi/install*/initrd.gz)"/initrd.gz
bsdcat "$initrd_path" | bsdcpio -i
cp "$project_path"/mkdi/preseed.cfg .
echo 'export DEBIAN_FRONTEND=text
' > lib/debian-installer.d/S99text-frontend
rm "$initrd_path"
find . | bsdcpio -oz --format=newc > "$initrd_path"
rm -r ./*
# do the same for "gtk/initrd.gz"
initrd_gtk_path="$(dirname "$project_path"/.cache/mkdi/install*/gtk/initrd.gz)"/initrd.gz
bsdcat "$initrd_gtk_path" | bsdcpio -i
cp "$project_path"/mkdi/preseed.cfg .
echo 'export DEBIAN_FRONTEND=text
' > lib/debian-installer.d/S99text-frontend
rm "$initrd_gtk_path"
find . | bsdcpio -oz --format=newc > "$initrd_gtk_path"
cd "$project_path"/.cache/mkdi; rm -r initrd

# prepend the microcode to initrd
# https://docs.kernel.org/x86/microcode.html#early-load-microcode

# U-Boot distro: /boot/extlinux/extlinux.conf

# regenerate "md5sum.txt" file
rm md5sum.txt && true
xorriso -osirrox on -indev "$debian_image" -cpx /md5sum.txt md5sum.txt
# remove the lines corresponding to the initrd files
grep -v "initrd.gz" md5sum.txt > tmpfile && mv tmpfile md5sum.txt
# add the md5sum of the new initrd files
md5sum ./install*/initrd.gz ./install*/gtk/initrd.gz >> md5sum.txt

# download and extract firmware archive
rm SHA512SUMS && true
wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/SHA512SUMS
if [ -f firmware.tar.gz ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  echo "using priviously downloaded firmware archive"
else
  [ -f firmware.tar.gz ] && rm firmware.tar.gz
  wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/firmware.tar.gz
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded firmware archive failed; try again"
    exit 1
  }
fi
rm -r firmware && true
mkdir firmware
cd firmware
tar -xzf "$project_path"/.cache/mkdi/firmware.tar.gz
[ -d firmware ] && { mv firmware/* .; rmdir firmware; }
cd "$project_path"/.cache/mkdi

# generate the modified iso file
[ -f debian-modified-"$1"-netinst.iso ] && rm debian-modified-"$1"-netinst.iso
xorriso -indev "$debian_image" -outdev debian-modified-"$1"-netinst.iso \
  -overwrite on -pathspecs off -cd / \
  -add install*/initrd.gz install*/gtk/initrd.gz md5sum.txt firmware \
  -map "$project_path"/mkdi/preseed.sh /comshell/preseed.sh \
  -map "$project_path"/os/ /comshell/os/ \
  -map "$project_path"/comshell-py/ /comshell/comshell-py/

sh "$project_path"/os/sd write /dev/"$2" debian-modified-"$1"-netinst.iso
echo 'Debian installation media created successfully'
