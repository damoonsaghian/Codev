#!/usr/bin/env sh

# use /boot/pcrsig (in efi partition) to unseal the luks key
# tpm2_nvread

# load signer public key to the tpm
tpm2_loadexternal -G rsa -C o -u signing_key_public.pem -c signing_key.ctx -n signing_key.name
# verify signature on the PCR policy and generate verification ticket
tpm2_verifysignature -c signing_key.ctx -g sha256 -m set2.pcr.policy -s set2.pcr.signature -t verification.tkt -f rsassa
# satisfy PCR policy and authorized policy
tpm2_startauthsession --policy-session -S session.ctx
tpm2_policypcr -l sha256:0 -S session.ctx
tpm2_policyauthorize -S session.ctx -i set2.pcr.policy -n signing_key.name -t verification.tkt
# unseal the secret and pipe to cryptsetup to open the LUKS encrypted volume
losetup $loopdevice enc.disk
tpm2_unseal -p session:session.ctx -c 0x81010001 | cryptsetup luksOpen --key-file=- $loopdevice enc_volume
tpm2_flushcontext session.ctx
mount /dev/mapper/enc_volume mountpoint/

# if failed, warn the user that the system is tampered with
# 	ask the user to enter password only if she is sure that the source of tamper is herself

# if unseal was successful but decryption of root is failed, it means that:
# , the root is replaced
# , the key based slot of luks header is corrupted
# so try other keys
# if all fails, ask the user to connect a backup storage device
# then try to decrypt luks devices, and when successful, copy it luks header onto the corrupted one
