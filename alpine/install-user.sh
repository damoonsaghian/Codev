# ask the user to provide different passwords for root and for the user
<<#
while ! passwd ; do
	echo "try again"
done

echo -n "choose a username: "; read username
useradd -m $username
while ! passwd user1; do
	echo "try again"
done
#

adduser user1 netdev

# since proc is mounted with hidepid, the following script is secure
# https://askubuntu.com/questions/611580/how-to-check-the-password-entered-is-a-valid-password-for-this-user
cat <<'__EOF__' > /usr/local/share/su-chkpasswd.sh
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

echo -n '#!doas /bin/sh
set -e
user_vt="$(cat /sys/class/tty/tty0/active | cut -c 4-)"
# switch to the first available virtual terminal and ask for root password,
#   and if successful, run the given command
if openvt -sw -- /bin/sh /usr/localshare/su-chkpasswd.sh "$@"; then
	chvt "$user_vt"
	$@
else
	chvt "$user_vt"
	echo "authentication failure"
fi
' > /usr/local/bin/su
chmod +x /usr/local/bin/su

echo 'permit nolog nopass user1 cmd /bin/sh args /usr/local/bin/su' >> /etc/doas.conf
# lock root account
passwd --lock root
