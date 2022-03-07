set -e

project_path="$(dirname "$0")/.."

# format the disk as an EFI partition
sh "$project_path"/os/sd format fat-efi /dev/"$1"

if [ "$3" = bios ]; then
  syslinux
fi

udisksctl mount -b /dev/"$1"1
mountpath="$(findmnt --noheadings --raw -o target --source /dev/"$1"1)"

mkdir -p "$project_path"/.cache/downloads && true
cd "$project_path"/.cache/downloads

# download and verify Debian installation image
rm SHA512SUMS && true
wget https://cdimage.debian.org/debian-cd/current/"$2"/iso-cd/SHA512SUMS
if [ -f debian-*-"$2"-netinst.iso ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  echo "using priviously downloaded installation image"
else
  [ -f debian-*-"$2"-netinst.iso ] && rm debian-*-"$2"-netinst.iso
  wget --recursive --level=1 --no-directories \
    --accept "debian-*-"$2"-netinst.iso" --reject "debian-*-*-"$2"-netinst.iso" \
    https://cdimage.debian.org/debian-cd/current/"$2"/iso-cd/
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded installation image failed; try again"
    exit 1
  }
fi

bsdtar -xf debian-*-"$2"-netinst.iso -C "$mountpath"

# download and extract firmware archive
cd "$project_path"/.cache/downloads
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
mkdir "$mountpath"/firmware && true
cd "$mountpath"/firmware
tar -xzf "$project_path"/.cache/downloads/firmware.tar.gz
[ -d firmware ] && { mv firmware/* .; rmdir firmware }

mkdir "$mountpath"/comshell
cp -r "$project_path"/comacs "$mountpath"/comshell/
cp -r "$project_path"/os "$mountpath"/comshell/

### initrd preseeding

rm -r "$project_path"/.cache/initrd && true
mkdir -p "$project_path"/.cache/initrd
cd "$project_path"/.cache/initrd

# add "preseed.cfg" to "initrd.gz"
initrd_path="$(dirname "$mountpath"/install*/initrd.gz)"
chmod +w -R "$(dirname "$initrd_path")"
bsdcat "$initrd_path" | bsdcpio -i
cp "$project_path"/os/preseed.cfg .
find | bsdcpio -oz --format=newc > "$initrd_path"
chmod -w -R "$(dirname "$initrd_path")"
rm -r *
# do the same for "gtk/initrd.gz"
initrd_gtk_path="$(dirname "$mountpath"/install*/gtk/initrd.gz)"
chmod +w -R "$(dirname "$initrd_gtk_path")"
bsdcat "$initrd_gtk_path" | bsdcpio -i
cp "$project_path"/os/preseed.cfg .
find | bsdcpio -oz --format=newc > "$initrd_gtk_path"
chmod +w -R "$(dirname "$initrd_gtk_path")"

cd "$mountpath"
rm -r "$project_path"/.cache/initrd

# regenerate "md5sum.txt" file
# remove the lines corresponding to the initrd files
grep -v "initrd.gz" md5sum.txt > tmpfile && mv tmpfile md5sum.txt
# add the md5sum of the new initrd files
md5sum ./install*/initrd.gz ./install*/gtk/initrd.gz >> md5sum.txt

echo 'Debian installation media created successfully'
