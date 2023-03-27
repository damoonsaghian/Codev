# kbd is needed for its chvt and openvt
apt-get install --yes kbd

# since proc is mounted with hidepid, the following script is secure
# https://wiki.debian.org/Hardening#Mounting_.2Fproc_with_hidepid
# https://askubuntu.com/questions/611580/how-to-check-the-password-entered-is-a-valid-password-for-this-user
cat <<'__EOF__' > /usr/local/share/sudo-chkpasswd.sh
set -e
root_passwd_hashed="$(sed -n '/root/p' /etc/shadow | cut -d ':' -f2)"
hash_method="$(echo "$root_passwd_hashed" | cut -d '$' -f2)"
case "$hashtype" in
	1) hashtype=md5 ;;
	5) hashtype=sha-256 ;;
	6) hashtype=sha-512 ;;
	*) echo "error: password hash type is unsupported"; exit 1 ;;
esac
salt="$(echo $root_passwd_hashed | cut -d '$' -f3)"
printf "enter root password: "
IFS= read -rs entered_passwd
entered_passwd_hashed="$(echo "$entered_passwd" | cryptpw -s --method="$hash_method" --salt="$salt")"
if [ "$entered_passwd_hashed" = "$root_passwd_hashed" ]; then
  exit 0
else
  exit 1
fi
__EOF__

echo -n '#!pkexec /bin/sh
set -e
user_vt="$(cat /sys/class/tty/tty0/active | cut -c 4-)"
# switch to the first available virtual terminal and ask for root password,
#   and if successful, run the given command
if openvt -sw -- /bin/sh /usr/localshare/sudo-chkpasswd.sh "$@"; then
	chvt "$user_vt"
	$@
else
	chvt "$user_vt"
	echo "authentication failure"
fi
' > /usr/local/bin/sudo
chmod +x /usr/local/bin/sudo

# let any user to run sudo
echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
	"http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
	<action id="codev.sudo.sudo">
		<description>sudo</description>
		<message>sudo</message>
		<defaults><allow_active>yes</allow_active></defaults>
		<annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
		<annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/sudo</annotate>
	</action>
</policyconfig>
' > /usr/share/polkit-1/actions/codev.sudo.policy

# lock root account
passwd --lock root
