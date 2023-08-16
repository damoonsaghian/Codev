;; if there is a saved session file for the project, restore it

;; backup: two'way diff

; https://github.com/Alexander-Miller/treemacs

;; left panel:
;; attached devices: udisksctl monitor
;; http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Manager.html#gdbus-method-org-freedesktop-UDisks2-Manager.GetBlockDevices
;;
;; dbus-send dbus-monitor
;;
;; ask the user if she wants to format the device, if:
;; , it's not formated
;; , it's a non'system device whose format is not vfat/exfat
;; , it's a system device whose format is not btrfs
;; http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-property-org-freedesktop-UDisks2-Block.HintSystem
;; http://storaged.org/doc/udisks2-api/latest/index.html
;; https://crates.io/crates/dbus
;;
;; use udisks to format non'system devices with vfat or exfat (if wants files bigger than 4GB)
;; http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-method-org-freedesktop-UDisks2-Block.Format
;; type: fat
;; mkfs-args: -F, 32, -I (to override partitions)
;; for system devices:
;; ; sudo sh -c "mkfs.btrfs -f <dev-path>; mount <dev-path> /mnt; chmod 777 /mnt; umount /mnt"
;; 
;; projects on VFAT/exFAT formated devices will be opened as read'only
;; when you try to edit them, you will be asked to copy them on to a BTRFS formated device
;;
;; mount it (if it's not)
;; http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Filesystem.html#gdbus-method-org-freedesktop-UDisks2-Filesystem.Mount
