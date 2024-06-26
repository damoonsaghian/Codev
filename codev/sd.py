# storage devices

# https://docs.gtk.org/gio/class.VolumeMonitor.html

# to see if it's a system device, and what is its format
# http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-property-org-freedesktop-UDisks2-Block.HintSystem
# http://storaged.org/doc/udisks2-api/latest/index.html
# https://lazka.github.io/pgi-docs/#Gio-2.0/classes/DBusConnection.html
# https://gjs.guide/guides/gio/dbus.html#direct-calls
# https://gjs.guide/guides/glib/gvariant.html#basic-usage

# to get the volume identifier
# https://docs.gtk.org/gio/iface.Volume.html

# use udisks to format devices
# http://storaged.org/doc/udisks2-api/latest/gdbus-org.freedesktop.UDisks2.Block.html#gdbus-method-org-freedesktop-UDisks2-Block.Format
# type: fat
# mkfs-args: -F, 32, -I (to override partitions)

# https://docs.gtk.org/gio/method.Volume.mount.html
