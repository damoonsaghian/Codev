set -e

# temporary solution, until "simple_agent" is implemented
bluetoothctl; exit

# it seems that normal users can use Bluez to connect devices globally (ie for all users)
# is this also true for keyboards and headsets?
# if it is, then it's a security flaw

# the correct usage domain for Bluetooth is personal devices like headsets
# it perfectly makes sense to pair them per user
# since keyboards are used for login, they must be paired globally
# still, even pairing of keyboards doesn't need root access,
#   because in this system, when a keyboard is connected, others are disabled, and current session gets locked

# Bluetooth keyboards must have an already paired Bluetooth dongle, or an additional USB connection

mode="$(printf "add\nremove\n" | bemenu -p system/bluetooth)"

if [ "$mode" = remove ]; then
  device_mac="$(bluetoothctl devices | bemenu -p system/bluetooth -l 30 |
    { read _first device_mac; echo $device_mac; })"
  bluetoothctl disconnect "$device_mac"
  bluetoothctl untrust "$device_mac"
  bluetoothctl remove "$device_mac"
  exit
fi

bluetoothctl power on
bluetoothctl scan on &
device_mac="$({ sleep 3; bluetoothctl devices; } | bemenu -p system/bluetooth -l 30 |
  { read _first device_mac; echo $device_mac; })"

simple_agent () {
  true
  # https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/test/simple-agent
  # https://ukbaz.github.io/howto/python_gio_1.html
  # https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/doc/device-api.txt
}

temp_file="$(mktemp -q)"

{
  bluetoothctl connect "$device_mac" &&
  bluetoothctl trust "$device_mac" ||
  bluetoothctl untrust "$device_mac"
} &> $temp_file &
simple_agent
cat $temp_file
rm $temp_file
