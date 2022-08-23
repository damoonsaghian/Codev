set -e

echo "not yet implemented"; exit

# it seems that normal users can use Bluez to connect devices globally (ie for all users)
# is this also true for keyboards and headsets?
# if it is, then it's a security flaw

# the correct usage domain for Bluetooth is personal devices like headsets
# it perfectly makes sense to pair them per user
# since keyboards are used for login, they must be paired globally
# still, even pairing of keyboards doesn't need root access,
#   because in this system, when a keyboard is connected, others are disabled, and current session gets locked

# Bluetooth keyboards must have an already paired Bluetooth dongle, or an additional USB connection

printf "do you want to forget an already paired device (y/N): "
read -r forget_mode

if [ "$forget_mode" = y ]; then
  bluetoothctl paired-devices
  printf "select a device (enter the MAC address): "
  read -r mac_address
  bluetoothctl disconnect "$mac_address"
  bluetoothctl untrust "$mac_address"
  exit
fi

bluetoothctl scan on
printf "select a device (enter the MAC address): "
read -r mac_address

if bluetoothctl --agent -- pair "$mac_address"; then
  bluetoothctl trust "$mac_address"
  bluetoothctl connect "$mac_address"
else
  bluetoothctl untrust "$mac_address"
fi
