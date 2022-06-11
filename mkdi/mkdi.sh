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
# for "amd64" and "i386" architectures download the installation images which include non'free firmwares
# cause the ucose must be send to kernel
# see if ucode is present in "install.amd" directory
# https://cdimage.debian.org/cdimage/unofficial/non-free/cd-including-firmware/current/
rm SHA512SUMS && true
wget https://cdimage.debian.org/debian-cd/current/"$1"/iso-cd/SHA512SUMS
if [ -f debian-*-"$1"-netinst.iso ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  echo "using priviously downloaded installation image"
else
  [ -f debian-*-"$1"-netinst.iso ] && rm debian-*-"$1"-netinst.iso
  wget --recursive --level=1 --no-directories \
    --accept "debian-*-"$1"-netinst.iso" --reject "debian-*-*-"$1"-netinst.iso" \
    https://cdimage.debian.org/debian-cd/current/"$1"/iso-cd/
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded installation image failed; try again"
    exit 1
  }
fi

# extract "initrd.gz" from the iso file
rm -r install* && true
xorriso -osirrox on -indev debian-*-"$1"-netinst.iso -extract_l / ./ '/install*/initrd.gz'
xorriso -osirrox on -indev debian-*-"$1"-netinst.iso -extract_l / ./ '/install*/gtk/initrd.gz'
rm -r "$project_path"/.cache/mkdi/initrd && true
mkdir -p "$project_path"/.cache/mkdi/initrd
cd "$project_path"/.cache/mkdi/initrd
# add "preseed.cfg" to "initrd.gz"
initrd_path="$(dirname "$project_path"/.cache/mkdi/install*/initrd.gz)"/initrd.gz
bsdcat "$initrd_path" | bsdcpio -i
cp "$project_path"/os/preseed.cfg .
cp "$project_path"/os/preseed.sh .
find | bsdcpio -oz --format=newc > "$initrd_path"
rm -r *
# do the same for "gtk/initrd.gz"
initrd_gtk_path="$(dirname "$project_path"/.cache/mkdi/install*/gtk/initrd.gz)"/initrd.gz
bsdcat "$initrd_gtk_path" | bsdcpio -i
cp "$project_path"/os/preseed.cfg .
cp "$project_path"/os/preseed.sh .
find | bsdcpio -oz --format=newc > "$initrd_gtk_path"
cd "$project_path"/.cache/mkdi

# regenerate "md5sum.txt" file
rm md5sum.txt && true
xorriso -osirrox on -indev debian-*-"$1"-netinst.iso -cpx /md5sum.txt md5sum.txt
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
mkdir firmware && true
cd firmware
rm -r *
tar -xzf ../firmware.tar.gz
[ -d firmware ] && { mv firmware/* .; rmdir firmware }
cd "$project_path"/.cache/mkdi

# generate the modified iso file
[ -f debian-modified-"$1"-netinst.iso ] && rm debian-modified-"$1"-netinst.iso
xorriso -indev debian-*-"$1"-netinst.iso -outdev debian-modified-"$1"-netinst.iso \
  -overwrite on -pathspecs off -cd / \
  -add "$initrd_path" "$initrd_gtk_path" md5sum.txt firmware \
  -map "$project_path"/os/ /comshell/os/ \
  -map "$project_path"/comacs/ /comshell/comacs/

sh "$project_path"/os/sd write /dev/"$2" debian-modified-"$1"-netinst.iso
echo 'Debian installation media created successfully'
