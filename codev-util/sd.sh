# mounting and formatting storage devices

script_dir="$(dirname "$(realpath "$0")")"

# mount with suid bits disabled
# mount to ~/.local/state/mounts

# if queued trim is supported, use discard option when mounting
if [ "$(cat /sys/block/"$device"/queue/discard_granularity)" -gt 0 ] &&
	[ "$(cat /sys/block/"$device"/queue/discard_max_bytes)" -gt 2147483648 ]
then
fi

# before unmount, run "fstrim <mount-point>" for devices supporting unqueued trim
# [ "$(cat /sys/block/"$device"/queue/discard_granularity)" -gt 0 ] &&
# [ "$(cat /sys/block/"$device"/queue/discard_max_bytes)" -lt 2147483648 ] &&

# exit if it's the system device

# format devices
# type: fat
# mkfs-args: -F, 32, -I (to override partitions)
# format non'system devices, format with vfat or exfat (if wants files bigger than 4GB)
# for system devices:
# doas sh -c "mkfs.btrfs -f <dev-path>; mount <dev-path> /mnt; chmod 777 /mnt; umount /mnt"

[ "$1" = new-sys ] && . "$script_dir"/sd-new-sys
