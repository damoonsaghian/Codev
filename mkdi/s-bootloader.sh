# flash-kernel way of dealing with kernel and initrd images is very diverse
# this makes implementing atomic upgrades impossible
# so see if flash-kernel is installed, remove it and warn the user
#
# MIPS systems are not supported for a similar reason
#   (newer MIPS systems may not have this problem, but MIPS is moving to RISCV anyway, so why bother)
# also s390x is not supported because
#   ZIPL (the bootloader on s390x) only understands data'blocks (not a filesystem),
#   and the boot partition must be rewritten everytime kernel/initrd is updated
# so for the bootloader we only have to deal with these:
# , for UEFI use systemd-boot
# , for Bios and PPC (OpenFirmware, Petitboot) use Grub

# UEFI needs a separate VFAT boot partition
# separate boot partition and atomic upgrades can live together becasue Debian keeps old kernel and modules
# and the fact that systemd-boot implements boot counting and automatic fallback to
#   older working boot entries on failure
#   https://systemd.io/AUTOMATIC_BOOT_ASSESSMENT/
# https://manpages.debian.org/unstable/systemd-boot/systemd-boot.7.en.html
[ -d /boot/efi ] && {
  apt-get install --yes systemd-boot

  mkdir /boot/efi/loader
  printf 'timeout 0\neditor no\n' > /boot/efi/loader/loader.conf

  bootctl install --no-variables --esp-path=/boot/efi

  echo 1 > /etc/kernel/tries

  root_uuid="$(findmnt -n -o UUID /)"
  echo "root=UUID=$root_uuid ro quiet" > /etc/kernel/cmdline

  kernel_path=$(readlink -f /boot/vmlinu?)
  kernel_version="$(basename $kernel_path | sed -e 's/vmlinu.-//')"
  kernel-install add "$kernel_version" "$kernel_path" /boot/initrd.img-"$kernel_version"

  rm -f /etc/kernel/cmdline
}

# alternative method:
# bootctl remove --esp-path=/boot/efi
# change root partition's type to XBOOTLDR
# create /loader/entries/debian.conf which refers to these symlinks: /boot/vmlinu? /boot/initrd.img
# put BTRFS driver in /boot/efi//EFI/systemd/drivers/...arch.efi
# cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /boot/efi/EFI/BOOT/BOOTX64.EFI

# to have atomic upgrades for BIOS and OpenFirmware based systems,
#   the bootloader is installed once, and never updated
lock_grub () {
  printf '\nGRUB_TIMEOUT=0\nGRUB_DISABLE_OS_PROBER=true\n' >> /etc/default/grub
  # disable menu editing and other admin operations in Grub:
  echo '#! /bin/sh' > /etc/grub.d/09_user
  echo 'set superusers=""' >> /etc/grub.d/09_user
  echo 'set menuentry_id_option="--unrestricted $menuentry_id_option"' >> /etc/grub.d/09_user
  chmod +x /etc/grub.d/09_user
  grub-mkconfig -o /boot/grub/grub.cfg
}
[ "$(dpkg --print-architecture)" = 'i386' ] && [ ! -d /sys/firmware/efi ] && {
  apt-get install --no-install-recommends --yes grub2-common grub-pc-bin grub-pc
  apt-get remove --yes grub-pc
  lock_grub
}
[ "$(udpkg --print-architecture)" = 'amd64' ] && [ ! -d /sys/firmware/efi ] && {
  apt-get install --no-install-recommends --yes grub2-common grub-pc-bin grub-pc
  apt-get remove --yes grub-pc
  lock_grub
}
[ "$(udpkg --print-architecture)" = 'ppc64el' ] && {
  apt-get install --no-install-recommends --yes grub2-common grub-ieee1275-bin grub-ieee1275
  apt-get remove --yes grub-ieee1275
  lock_grub
}

# boot'firmware updates need special care
# unless there is a read_only backup, firmware update is not a good idea
# the same applies to updating Grub
# fwupd
