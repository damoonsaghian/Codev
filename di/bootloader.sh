# flash-kernel way of dealing with kernel and initrd images is very diverse
# this makes implementing atomic upgrades impossible
# so see if flash-kernel is installed, remove it and warn the user
command -v flash-kernel &>/dev/null && {
  apt-get remove --yes flash-kernel
  echo 'apparently your system needs "flash-kernel" package to boot'
  echo '  but since "flash-kernel" is not supported, your system may not boot'
}
# MIPS systems are not supported for a similar reason
#   (newer MIPS systems may not have this problem, but MIPS is moving to RISCV anyway, so why bother)
# also s390x is not supported because
#   ZIPL (the bootloader on s390x) only understands data'blocks (not a filesystem),
#   and the boot partition must be rewritten everytime kernel/initrd is updated
# so for the bootloader we only have to deal with these:
# , for UEFI use systemd-boot
# , for Bios and PPC (OpenFirmware, Petitboot) use Grub

# UEFI with systemd-boot needs a separate VFAT partition containing kernel and initrd images
# this and atomic upgrades can live together becasue Debian keeps old kernel and modules
# and the fact that systemd-boot implements boot counting and automatic fallback to
#   older working boot entries on failure
# https://manpages.debian.org/unstable/systemd-boot/systemd-boot.7.en.html#BOOT_COUNTING
# https://systemd.io/AUTOMATIC_BOOT_ASSESSMENT/
[ -d /boot/efi ] && {
  apt-get install --yes systemd-boot
  mkdir /boot/efi/loader
  printf 'timeout 0\neditor no\n' > /boot/efi/loader/loader.conf
  bootctl install --no-variables --esp-path=/boot/efi
  echo 1 > /etc/kernel/tries
  echo "root=UUID=$(findmnt -n -o UUID /) ro quiet" > /etc/kernel/cmdline
  kernel_path=$(readlink -f /boot/vmlinu?)
  kernel_version="$(basename $kernel_path | sed -e 's/vmlinu.-//')"
  kernel-install add "$kernel_version" "$kernel_path" /boot/initrd.img-"$kernel_version"
  rm -f /etc/kernel/cmdline
}

# to have atomic upgrades for BIOS and OpenFirmware based systems,
#   the bootloader is installed once, and never updated
lock_grub () {
  # since we will lock root, recovery entries are useless
  printf '\nGRUB_DISABLE_RECOVERY=true\nGRUB_DISABLE_OS_PROBER=true\nGRUB_TIMEOUT=0\n' >> /etc/default/grub
  # disable menu editing and other admin operations in Grub:
  echo '#! /bin/sh' > /etc/grub.d/09_user
  echo 'set superusers=""' >> /etc/grub.d/09_user
  echo 'set menuentry_id_option="--unrestricted $menuentry_id_option"' >> /etc/grub.d/09_user
  chmod +x /etc/grub.d/09_user
  grub-mkconfig -o /boot/grub/grub.cfg
}
architecture="$(udpkg --print-architecture)"
[ -d /sys/firmware/efi ] || { [ "$architecture" = 'i386' ] || [ "$architecture" = 'amd64' ]; } && {
  apt-get install --no-install-recommends --yes grub2-common grub-pc-bin grub-pc
  apt-get remove --yes grub-pc
  lock_grub
}
[ "$architecture" = 'ppc64el' ] && {
  apt-get install --no-install-recommends --yes grub2-common grub-ieee1275-bin grub-ieee1275
  apt-get remove --yes grub-ieee1275
  lock_grub
}
