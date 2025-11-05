apk_new add linux-stable

apk_new add intel-ucode && apk_new add amd-ucode

# self signed unified kernel image
# https://wiki.archlinux.org/title/Unified_kernel_image
# https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Using_your_own_keys
# https://gitlab.alpinelinux.org/alpine/mkinitfs
# https://wiki.archlinux.org/title/Microcode
# /boot/efi/boot/bootx64.efi
# /boot/efi/boot/bootaa64.efi
# /boot/efi/boot/bootriscv64.efi
