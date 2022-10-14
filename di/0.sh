set -e

echo 'this script will create a Debian installer on the storage device you choose'
echo '\e[1mwarning!\e[0m all data on the selected storage device will be deleted'
echo

choose () {
  # the list of choices with the indents removed
  list="$(printf "$2" | sed -r 's/^[[:blank:]]+//')"
  count="$(printf "$2" | wc -l)"
  index=1
  selected_line=""
  key=""
  while true; do
    # print the lines, highlight the selected one
    printf "$list" | {
      i=1
      while read line; do
        if [ $i = $index ]; then
          selected_line="$line"
          printf "  \e[7m$line\e[0m\n" # highlight
        else
          printf "  $line\n"
        fi
        i=$((i+1))
      done
    }

    if [ $index -eq 0 ]; then
      selected_line=""
      printf "\e[7mexit\e[0m" # highlighted
    else
      printf "\e[8mexit\e[0m" #hidden
    fi

    read -s -n1 key # wait for user to press a key
    
    # if key is empty, it means the read delimiter, ie the "enter" key was pressed
    [ -z "$key" ] && break

    if [ "$key" = "\177" ]; then
      index=0
    elif [ "$key" = " " ]; then
      index=$((index+1))
      [ $index -gt $count ] && i=1
    else
      # find the next line which its first character is "$key", and put the line's number in "index"
      i=index
      while true; do
        i=$((i+1))
        [ $i -gt $count ] && i=1
        [ $i -eq $index ] && break
        if [ "$(echo "$list" | sed -n "$i"p | cut -c1)" = "$key" ]; then
          index=i
          break
        fi
      done
    fi
    
    echo -en "\e[${count}A" # go up to the beginning to re'render
  done

  [ $index -eq 0 ] && echo
  eval "$1=\"$selected_line\""
  [ $index -eq 0 ] && exit
}

echo 'select a CPU architecture:'
choose arch 'amd64\nriscv64\nppc64el\narm64\narmhf\ni386\n'

wget2 -v &> /dev/null && alias wget=wget2

project_path="$(dirname "$0")/.."

mkdir -p "$project_path"/.cache/di
cd "$project_path"/.cache/di

# download and verify latest Debian installation iso
rm -f SHA512SUMS
wget https://cdimage.debian.org/debian-cd/current/"$arch"/iso-cd/SHA512SUMS
debian_image="$(printf debian-*-"$arch"-netinst.iso)"
wget --continue https://cdimage.debian.org/debian-cd/current/"$arch"/iso-cd/"$debian_image" 2> /dev/null || true
if [ -f "$debian_image" ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  true
else
  rm -f debian-*-"$arch"-netinst.iso
  wget --recursive --level=1 --no-directories \
    --accept "debian-*-$arch-netinst.iso" --reject "debian-*-*-$arch-netinst.iso" \
    https://cdimage.debian.org/debian-cd/current/"$arch"/iso-cd/
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded installation image failed; try again"
    exit 1
  }
  debian_image="$(printf debian-*-"$arch"-netinst.iso)"
fi

# download and extract firmware archive
rm -f SHA512SUMS
wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/SHA512SUMS
if [ -f firmware.tar.gz ] && sha512sum --check --status --ignore-missing SHA512SUMS; then
  true
else
  rm -f firmware.tar.gz
  wget https://cdimage.debian.org/cdimage/unofficial/non-free/firmware/stable/current/firmware.tar.gz
  sha512sum --check --status --ignore-missing SHA512SUMS || {
    echo "verifying the checksum of the downloaded firmware archive failed; try again"
    exit 1
  }
fi
rm -rf firmware
mkdir firmware
cd firmware
tar -xzf ../firmware.tar.gz
cd "$project_path"/.cache/di

# extract "initrd.gz" from the iso file
rm -rf install*
xorriso -osirrox on -indev "$debian_image" -extract_l / ./ '/install*/initrd.gz'
xorriso -osirrox on -indev "$debian_image" -extract_l / ./ '/install*/gtk/initrd.gz'
initrd_rpath="$(printf install*/initrd.gz)"
initrd_gtk_rpath="$(printf install*/gtk/initrd.gz)"

mkdir -p extracted-files
bsdtar -xf "$debian_image" -C ./extracted-files

# add "preseed.cfg" to "initrd.gz", and force Debian installer to use text frontend
rm -rf initrd
mkdir -p initrd
cd "$project_path"/.cache/di/initrd
bsdcat ../"$initrd_rpath" | bsdcpio -i
cp "$project_path"/di/preseed.cfg .
echo 'export DEBIAN_FRONTEND=text' > lib/debian-installer.d/S99text-frontend
rm -f "$project_path"/.cache/di/"$initrd_rpath"
find . | bsdcpio -oz --format=newc > "$project_path"/.cache/di/"$initrd_rpath"
rm -rf ./*
# do the same for "gtk/initrd.gz"
bsdcat ../"$initrd_gtk_rpath" | bsdcpio -i
cp "$project_path"/di/preseed.cfg .
echo 'export DEBIAN_FRONTEND=text' > lib/debian-installer.d/S99text-frontend
rm -f "$project_path"/.cache/di/"$initrd_gtk_rpath"
find . | bsdcpio -oz --format=newc > "$project_path"/.cache/di/"$initrd_gtk_rpath"
cd "$project_path"/.cache/di
rm -rf initrd

# prepend the microcode to initrd
# https://docs.kernel.org/x86/microcode.html#early-load-microcode

# regenerate "md5sum.txt" file
rm -f md5sum.txt
xorriso -osirrox on -indev "$debian_image" -cpx /md5sum.txt md5sum.txt
# remove the lines corresponding to the initrd files
sed -n "/initrd.gz/d" md5sum.txt
# add the md5sum of the new initrd files
md5sum ./"$initrd_rpath" ./"$initrd_gtk_rpath" >> md5sum.txt

case "$arch" in amd64|ppc64el|i386)
  printf 'do you want the installer to support legacy boot firmwares, ie BIOS and OpenFirmware (y/N):'
  read legacy_boot_firmwares
;; esac

removable_devices="$(lsblk --nodep --noheadings -o RM,NAME,SIZE,MODEL | sed -nr 's/^[[:blank:]]+1[[:blank:]]+//p')"
echo 'select a storage device:'
echo '\e[1mwarning!\e[0m all data on the selected storage device will be deleted'
choose device "$(printf "$removable_devices")"
device="$(printf "$device" | cut -d ' ' -f1)"

if [ "$legacy_boot_firmwares" = y ]; then
  # create a vfat efi partition, and copy the files
  # dbus-send
else
  # generate the modified iso file
  [ -f debian-modified-"$arch"-netinst.iso ] && rm -f debian-modified-"$arch"-netinst.iso
  xorriso -indev "$debian_image" -outdev debian-modified-"$arch"-netinst.iso \
    -overwrite on -pathspecs off -cd / \
    -add firmware "$initrd_rpath" "$initrd_gtk_rpath" md5sum.txt \
    -map "$project_path"/di/ '/comshell/di/' \
    -map "$project_path"/comshell-py/ '/comshell/comshell-py/'
  
  #.cache/di/debian-modified-amd64-netinst.iso /dev/"$device"
  # dbus-send OpenDevice
fi

echo 'Debian installation media created successfully'
