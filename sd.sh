# mounting and formatting storage devices

# mount with suid bits disabled
# mount to ~/.local/state/mounts

# exit if it's the system device

# format devices
# type: fat
# mkfs-args: -F, 32, -I (to override partitions)
# format non'system devices, format with vfat or exfat (if wants files bigger than 4GB)
# for system devices:
# sudo sh -c "mkfs.btrfs -f <dev-path>; mount <dev-path> /mnt; chmod 777 /mnt; umount /mnt"
