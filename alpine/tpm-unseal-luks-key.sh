#!/usr/bin/env sh

# use /boot/pcrsig (in efi partition) to unseal the luks key
# sudo tpm2_unseal -H 0x81000000 -L sha1:4,9,12

# if failed, warn the user that the system is tampered with
# 	ask the user to enter password only if she is sure that the source of tamper is herself

# if unseal was successful but decryption of root is failed, it means that:
# , the root is replaced
# , the key based slot of luks header is corrupted
# so ask the user to connect a backup storage device
# then try to decrypt luks devices, and when successful, copy it luks header onto the corrupted one
