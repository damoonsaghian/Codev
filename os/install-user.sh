apt-get -qq install dbus-user-session pkexec kbd physlock whois
# kbd is needed for its openvt and chvt
# whois is needed for its mkpasswd

cat <<'__EOF__' > /usr/local/bin/chkpasswd
#!/bin/bash
set -e
username="$1"
prompt="$2"
passwd_hashed="$(sed -n "/$username/p" /etc/shadow | cut -d ':' -f2 | cut -d '!' -f 2)"
salt="$(echo "$passwd_hashed" | grep -o '.*\$')"
printf "$prompt "
IFS= read -rs entered_passwd
echo
entered_passwd_hashed="$(MKPASSWD_OPTIONS="-S $salt" mkpasswd -s <<< "$entered_passwd")"
if [ "$entered_passwd_hashed" = "$passwd_hashed" ]; then
  exit 0
else
  exit 1
fi
__EOF__
chmod +x /usr/local/bin/chkpasswd

cat <<'__EOF__' > /usr/local/bin/sudo
#!/usr/bin/env -S pkexec --keep-cwd /bin/bash
set -e
# switch to the first available virtual terminal and ask for root password
# and if successful, run the given command
prompt_command="\\e[92m$(printf "%q " "$@")\\e[0m"
prompt="$prompt_command\nPWD: $PWD\nsudo password:"
if openvt -sw -- /usr/local/bin/chkpasswd root "$prompt"; then
	"$@"
else
	echo "authentication failure"
fi
__EOF__
chmod +x /usr/local/bin/sudo

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
	"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
	<action id="org.local.pkexec.sudo">
		<description>sudo</description>
		<message>sudo</message>
		<defaults><allow_active>yes</allow_active></defaults>
		<annotate key="org.freedesktop.policykit.exec.path">/bin/bash</annotate>
		<annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/sudo</annotate>
	</action>
</policyconfig>
' > /usr/share/polkit-1/actions/org.local.pkexec.sudo.policy

cat <<'__EOF__' > /usr/local/bin/lock
#!/usr/bin/pkexec /bin/sh
set -e
chkpasswd="/usr/local/bin/chkpasswd \"$(logname)\" 'password:'"
user_vt="$(cat /sys/class/tty/tty0/active | cut -c 4-)"
deallocvt
openvt --switch --console=12 -- sh -c \
	"setterm --blank 1; physlock -l;
	sleep_time=0;
	while ! $chkpasswd; do sleep_time=\$((sleep_time+1)); sleep \$sleep_time; done && {
		setterm --blank 0
		physlock -L
		chvt \"$user_vt\"
	}"
__EOF__
chmod +x /usr/local/bin/lock

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
	"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
	<action id="org.local.pkexec.lock">
		<description>lock</description>
		<message>lock</message>
		<defaults><allow_active>yes</allow_active></defaults>
		<annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
		<annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/lock</annotate>
	</action>
</policyconfig>
' > /usr/share/polkit-1/actions/org.local.pkexec.lock.policy

# allow udisks2 to mount all devices except when it's an EFI partition
echo -n 'polkit.addRule(function(action, subject) {
	function isNotEfiPartition(devicePath) {
		var partitionType = polkit.spawn(["lsblk", "--noheadings", "-o", "PARTTYPENAME", devicePath]);
		if (partitionType.indexOf("EFI System") === -1) return true;
	}
	if (subject.local && subject.active &&
		action.id === "org.freedesktop.udisks2.filesystem-mount-system" &&
		isNotEfiPartition(action.lookup("device"))
	) {
		return polkit.Result.YES;
	}
});
' > /etc/polkit-1/rules.d/49-udisks.rules

# console level keybinding: when "F8" or "XF86Lock" is pressed: /usr/local/bin/lock

# to prevent BadUSB, when a new input device is connected lock the session
echo 'ACTION=="add", ATTR{bInterfaceClass}=="03" RUN+="/usr/local/bin/lock"' > \
	/etc/udev/rules.d/80-lock-new-hid.rules

echo; echo -n "set username: "
read -r username
groupadd -f netdev; groupadd -f bluetooth
useradd --create-home --groups "$username",netdev,bluetooth --shell /bin/bash "$username" || true
echo >> "/home/$username/.bashrc"
cat <<'__EOF__' >> "/home/$username/.bashrc"
export PS1="\e[7m \u@\h \e[0m \e[7m \w \e[0m\n> "
shopt -q login_shell && echo
echo 'enter "system" to configure system settings'
__EOF__

while ! passwd --quiet "$username"; do
	echo "an error occured; please try again"
done
echo; echo "set sudo password"
while ! passwd --quiet; do
	echo "an error occured; please try again"
done
# lock root account
passwd --lock root

# guest user
useradd --create-home --shell /bin/bash guest || true
passwd --quiet --delete guest
printf 'no user account? login as "guest"\n\n' >> /etc/issue
echo >> "/home/guest/.bashrc"
cat <<'__EOF__' >> "/home/guest/.bashrc"
export PS1="\e[7m \u@\h \e[0m \e[7m \w \e[0m\n> "
shopt -q login_shell && echo
echo 'enter "system" to configure system settings'
__EOF__
