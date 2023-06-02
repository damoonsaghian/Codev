apt-get --yes install kbd whois pkexec
# kbd is needed for its openvt
# whois is needed for its mkpasswd

cat <<'__EOF__' > /usr/local/bin/sudo-chkpasswd
#!/bin/bash
set -e
root_passwd_hashed="$(sed -n '/root/p' /etc/shadow | cut -d ':' -f2)"
hash_method="$(echo "$root_passwd_hashed" | cut -d '$' -f2)"
case "$hash_method" in
	1) hash_method=md5 ;;
	5) hash_method=sha-256 ;;
	6) hash_method=sha-512 ;;
	*) echo "error: password hash type is unsupported"; exit 1 ;;
esac
salt="$(echo "$root_passwd_hashed" | cut -d '$' -f3)"
printf "enter root password: "
IFS= read -rs entered_passwd
entered_passwd_hashed="$(MKPASSWD_OPTIONS="--method='$hash_method' '$entered_passwd' '$salt'" mkpasswd)"
if [ "$entered_passwd_hashed" = "$root_passwd_hashed" ]; then
  exit 0
else
  exit 1
fi
__EOF__
chmod +x /usr/local/bin/sudo-chkpasswd
# https://askubuntu.com/questions/611580/how-to-check-the-password-entered-is-a-valid-password-for-this-user

echo -n '#!pkexec /bin/sh
set -e
# switch to the first available virtual terminal and ask for root password,
#   and if successful, run the given command
if openvt -sw -- /usr/local/bin/sudo-chkpasswd "$@"; then
	$@
else
	echo "authentication failure"
fi
' > /usr/local/bin/sudo
chmod +x /usr/local/bin/sudo

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
