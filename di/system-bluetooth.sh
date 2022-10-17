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

choose mode "add\nremove"

if [ "$mode" = remove ]; then
  choose device_mac "$(bluetoothctl devices)"
  device_mac="$(echo "$device_mac" | { read _first device_mac; echo $device_mac; })"
  bluetoothctl disconnect "$device_mac"
  bluetoothctl untrust "$device_mac"
  bluetoothctl remove "$device_mac"
  exit
fi

bluetoothctl power on
bluetoothctl scan on &
sleep 3
choose device_mac "$(bluetoothctl devices)"
device_mac="$(echo "$device_mac" | { read _first device_mac; echo $device_mac; })"

simple_agent() {
  true
  # https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/test/simple-agent
  # https://ukbaz.github.io/howto/python_gio_1.html
  # https://git.kernel.org/pub/scm/bluetooth/bluez.git/tree/doc/device-api.txt
}

bluetoothctl connect "$device_mac" &&
bluetoothctl trust "$device_mac" ||
bluetoothctl untrust "$device_mac"

simple_agent

temp_file="$(mktemp -q)"
cat $temp_file
rm $temp_file
