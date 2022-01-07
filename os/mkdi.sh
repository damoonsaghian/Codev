cd "$(dirname "$0")"
cd ..

# download and verify Debian installation image
[ -d .cache/os ] || mkdir -p .cache/os
cd .cache/os
rm SHA512SUMS
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
    rm debian-*-"$1"-netinst.iso
    exit
  }
fi
cd ..; cd ..

mountpoint=$(sh os/sd mount .cache/os/debian-*-"$1"-netinst.iso)

cd "$mountpoint"
initrd=$(echo install*/initrd.gz)
initrd_gtk=$(echo install*/gtk/initrd.gz)
cd "$(dirname "$0")"
cd ..

# add "preseed.cfg" to "initrd.gz"
cd .cache/os
cp "$mountpoint"/"$initrd" initrd.gz
gunzip initrd.gz
echo ../preseed.cfg | cpio -H newc -o -A -F initrd
gzip initrd
cp "$mountpoint"/"$initrd_gtk" initrd-gtk.gz
gunzip initrd-gtk.gz
echo ../preseed.cfg | cpio -H newc -o -A -F initrd-gtk
gzip initrd-gtk
cd ..; cd ..

umount "$mountpoint"

# download and extract firmwares
cd .cache/os
rm SHA512SUMS
wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/SHA512SUMS
if [ -f firmware.tar.gz ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  echo "using priviously downloaded firmwares"
else
  [ -f firmware.tar.gz ] && rm firmware.tar.gz
  wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/firmware.tar.gz
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded firmwares failed; try again"
    rm firmware.tar.gz
    exit
  }
fi
[ -d firmware] || mkdir firmware
cd firmware
rm -r *
tar -xzf ../firmware.tar.gz
[ -d firmware ] && { mv firmware/* .; rmdir firmware }
cd ..
cd ..; cd ..

# regenerate md5sum.txt

xorriso -dev .cache/os/debian-*-"$1"-netinst.iso -overwrite on \
  -map .cache/os/initrd.gz "$initrd" \
  -map .cache/os/initrd-gtk.gz "$initrd_gtk" \
  -map .cache/os/firmware/ /firmware \
  -map os/ /comshell/os/ \
  -map comacs/ /comshell/comacs/ \
  -commit_eject all

# unmount all partitions on the device
umount /dev/"$2"?*

sh sd write /dev/"$2" .cache/os/debian-*-"$1"-netinst.iso

umount /dev/"$2"?*
echo 'Debian installation media created successfully'
