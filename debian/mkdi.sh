set -e

# download the Debian installation image into ".cache" directory

# add "preseed.cfg" to "initrd.gz":
cd .cache/debian-extracted/install.*
chmod +w -R .
gunzip initrd.gz
echo ../preseed.cfg | cpio -H newc -o -A -F initrd
gzip initrd
chmod -w -R .

# also for the graphical installer:
cd .cache/debian-extracted/install.*/gtk
chmod +w -R .
gunzip initrd.gz
echo ../preseed.cfg | cpio -H newc -o -A -F initrd
gzip initrd
chmod -w -R .

# firmwares

# unmount all partitions on the device
umount /dev/"$2"?*

# dd

umount /dev/"$2"?*
echo 'Debian installation media created successfully'
