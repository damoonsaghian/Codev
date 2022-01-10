set -e

cd "$(dirname "$0")"
[ -d .cache ] || mkdir .cache
cd .cache

# download and verify Debian installation image
[ -f SHA512SUMS ] && rm SHA512SUMS
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
xorriso -osirrox on -indev debian-*-"$1"-netinst.iso -extract_l / ./ '/install*/initrd.gz'
xorriso -osirrox on -indev debian-*-"$1"-netinst.iso -extract_l / ./ '/install*/gtk/initrd.gz'
# add "preseed.cfg" to "initrd.gz"
cd install*
gunzip initrd.gz
echo ../../preseed.cfg | cpio -H newc -o -A -F initrd
gzip initrd
cd ..
cd install*/gtk
gunzip initrd.gz
echo ../../../preseed.cfg | cpio -H newc -o -A -F initrd
gzip initrd
cd ../..

# download and extract firmwares
[ -f SHA512SUMS ] && rm SHA512SUMS
wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/SHA512SUMS
if [ -f firmware.tar.gz ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  echo "using priviously downloaded firmwares"
else
  [ -f firmware.tar.gz ] && rm firmware.tar.gz
  wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/firmware.tar.gz
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded firmwares failed; try again"
    exit 1
  }
fi
[ -d firmware] || mkdir firmware
cd firmware
rm -r *
tar -xzf ../firmware.tar.gz
[ -d firmware ] && { mv firmware/* .; rmdir firmware }
cd ..

# regenerate md5sum.txt

# generate the modified iso file
[ -f debian-modified-"$1"-netinst.iso ] && rm debian-modified-"$1"-netinst.iso
xorriso -indev debian-*-"$1"-netinst.iso -outdev debian-modified-"$1"-netinst.iso \
  -overwrite on -pathspecs off -cd / \
  -add install*/initrd.gz install*/gtk/initrd.gz firmware \
  -map .. /comshell/os/ \
  -map ../../comacs/ /comshell/comacs/ \
  -commit_eject all

sh ../sd write /dev/"$2" debian-modified-"$1"-netinst.iso
echo 'Debian installation media created successfully'
