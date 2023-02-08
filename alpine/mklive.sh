set -e

. "$(dirname "$0")/pick.sh"

project_path="$(dirname "$0")/.."

echo 'select a CPU architecture:'
pick arch 'riscv64\nppc64le\naarch64\narmv7\nx86_64\nx86\ns390x'

url="https://dl-cdn.alpinelinux.org/alpine/latest-stable/releases/$arch"
# find the version number of the latest stable release
version="$(wget -q -O- "$url/latest-releases.yaml" | grep "version:" | head -1 | cut -d ':' -f 2 | cut -d ' ' -f 2)"

# download and verify Alpine live iso file
mkdir -p "$project_path/.cache/alpine"
cd "$project_path/.cache/alpine"
# remove old files
rm -f $(echo alpine-standard-*-"$arch".iso | sed s/"alpine-standard-$version-$arch.iso"//)
wget --continue "$url/alpine-standard-$version-$arch.iso" || true
wget --continue "$url/alpine-standard-$version-$arch.iso.sha256" || true
sha256sum --check --status "alpine-standard-$version-$arch.iso.sha256" || {
	echo "verifying the checksum of the downloaded file failed; try again"
	rm -f "alpine-standard-$version-$arch.iso" "alpine-standard-$version-$arch.iso.sha256"
	exit 1
}
# when Alpine starts to sign the checksum files with alpine-keys, verify the signature too

apk add --clean-protected xorriso

# extract initramfs from the iso file
rm -f "$project_path/.cache/alpine/initramfs-lts"
xorriso -osirrox on -indev "$project_path/.cache/alpine/$iso_file" -extract /boot/initramfs-lts \
	"$project_path/.cache/alpine/initramfs-lts"

initramfs_append_path="$project_path/.cache/alpine/initramfs-append"
rm -rf "$initrd_append_path"

# include the comshell files into the initramfs
mkdir -p "$initramfs_append_path/comshell"
cp -r "$project_path"/* "$initramfs_append_path/comshell/"

# manipulate initramfs to automatically login as root
mkdir -p "$initramfs_append_path/etc"
xorriso -osirrox on -indev "$project_path/.cache/alpine/$iso_file" -extract /etc/inittab \
	"$initramfs_append_path/etc/inittab"
sed "s/^tty1::respawn.*/tty1::respawn:\/bin\/login -f root/" "$initramfs_append_path/etc/inittab"

# manipulate initramfs to automatically run "setup.sh"
mkdir -p "$initramfs_append_path/etc/profile.d"
echo 'sh /comshell/alpine/setup.sh' > "$initramfs_append_path/etc/profile.d/zzz-setup.sh"

# append the files to initramfs
cd "$initramfs_append_path"
find . | cpio -H newc -o | gzip >> "$project_path/.cache/alpine/initramfs-lts"

# generate the modified iso file
# for x86/x86_64 add Intel and AMD microcodes too
rm -f "$project_path/.cache/alpine/alpine-comshell.iso"
if [ "$arch" = x86_64 ] || [ "$arch" = x86 ]; then
	apk add intel-ucode amd-ucode
	xorriso -osirrox on -indev "$project_path/.cache/alpine/$iso_file" \
		-extract /boot/syslinux/syslinux.cfg "$project_path/.cache/alpine/syslinux.cfg" \
		-extract /boot/grub/grub.cfg "$project_path/.cache/alpine/grub.cfg"
	sed "s/INITRD.*/INITRD \/boot\/intel-ucode.img,\/boot\/amd-ucode.img,\/boot\/initramfs-lts/" \
		"$project_path/.cache/alpine/syslinux.cfg"
	sed "s/initrd.*/initrd	\/boot\/intel-ucode.img \/boot\/amd-ucode.img \/boot\/initramfs-lts/" \
		"$project_path/.cache/alpine/grub.cfg"
	
	xorriso -indev "$project_path/.cache/alpine/$iso_file" -overwrite on \
		-map "$project_path/.cache/alpine/initramfs-lts" /boot/initramfs-lts \
		-map /boot/intel-ucode.img /boot/intel-ucode.img \
		-map /boot/amd-ucode.img /boot/amd-ucode.img \
		-map "$project_path/.cache/alpine/syslinux.cfg" /boot/syslinux/syslinux.cfg \
		-map "$project_path/.cache/alpine/grub.cfg" /boot/grub/grub.cfg \
		-outdev "$project_path/.cache/alpine/alpine-comshell.iso"
else
	xorriso -indev "$project_path/.cache/alpine/$iso_file" -overwrite on \
		-map "$project_path/.cache/alpine/initramfs-lts" /boot/initramfs-lts \
		-outdev "$project_path/.cache/alpine/alpine-comshell.iso"
fi

apk del -r --purge xorriso

# if we're on a live Alpine system, copy kernel modules from modloop and unmount loopback device
# so we can create the customized live system on the booted device itself
DO_UMOUNT=1 copy-modloop || true

show_block_devices() {
	local p= dev= disks= disk= model= d= size=
	for p in /sys/block/*/device; do
		dev="${p%/device}"
		dev=${dev#/sys/block/}
		disks="$disks $dev"
	done
	for disk in $disks; do
		dev="${disk#/dev/}"
		d=$(echo $dev | sed 's:/:!:g')
		model=$(cat /sys/block/$d/device/model 2>/dev/null)
		size=$(awk '{gb = ($1 * 512)/1000000000; printf "%.1f GB\n", gb}' /sys/block/$d/size 2>/dev/null)
		printf "\t%-10s %s\t%s\n" "$dev" "$size" "$model"
	done
}
echo "select a storage device to make an Alpine Linux live system on it:"
pick device "$(show_block_devices)"
device_name="$(echo "$device" | cut -d ' ' -f 1)"
printf "all data on \"$device_name\" will be deleted; do you want to continue? (y/N): "
read answer
[ "$answer" = y ] || exit

# if "sd" command is available use that, cause it can be run by non'root users
sd flash "$device_name" "$project_path/.cache/alpine-comshell.iso" ||
dd if="$project_path/.cache/alpine-comshell.iso" of="/dev/$device_name"

echo "Alpine live media created successfully"
echo "you can now remove the media"
