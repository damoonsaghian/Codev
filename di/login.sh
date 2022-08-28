apt-get install --no-install-recommends --yes dbus-user-session kbd openssl pkexec
# kbd is needed for its chvt and openvt

echo -n '#!/usr/bin/pkexec /bin/sh
set -e
navt=$(fgconsole --next-available)
systemctl start getty@tty"$navt".service
chvt "$navt"
echo "$navt" > /tmp/switch-user-vt
' > /usr/local/bin/switch-user
chmod +x /usr/local/bin/switch-user

# when a keyboard is connected, disable others, lock the session (if any), run "switch-user"
# loginctl lock-session; switch-user
# since password prompts only accept keyboard input, this is not necessary for headsets
# this has two benefits:
# , when you want to login you are sure that it's the login screen (not a fake one created by another user)
# , others can't access your session using an extra keyboard

cat <<'_EOF_' > /etc/profile.d/login-manager.sh
# run this script if running from tty1, or if put here by "switch-user"
if [ "$(tty)" = "/dev/tty1" ] || [ "$(fgconsole)" = "$(cat /tmp/switch-user-vt)" ]; then
  # if a user session is already running, switch to it, and unlock it
  # otherwise run sway (if this script is not called by a display manager, or by root)
  previous_session="$(loginctl show-user "$USER" --value --property=Sessions | cut -d ' ' -f2)"
  current_tty="$(basename $(tty))"
  if [ -n "$previous_session" ]; then
    loginctl activate "$previous_session" && {
      loginctl unlock-session "$previous_session"
      systemctl stop getty@"$current_tty".service
    }
  elif [ -z $DISPLAY ] && [ $(id -u) != 0 ]; then
    exec sway -c /usr/local/share/sway.conf
  fi
fi
_EOF_

groupadd su
# add the first user to su group
usermod -aG su "$(id -nu 1000)"

cat <<'_EOF_' > /usr/localshare/su-chkpasswd.sh
set -e
root_passwd_hashed="$(sed -n '/root/p' /etc/shadow | cut -d ':' -f2)"
hash_method="$(echo "$root_passwd_hashed" | cut -d '$' -f2)"
salt="$(echo $root_passwd_hashed | cut -d '$' -f3)"
printf "enter root password: "
IFS= read -rs entered_passwd
entered_passwd_hashed="$(echo "$entered_passwd" | openssl passwd -$hash_method -salt $salt -stdin)"
if [ "$entered_passwd_hashed" = "$root_passwd_hashed" ]; then
  exit 0
else
  exit 1
fi
_EOF_

echo -n '#!/usr/bin/pkexec /bin/sh
set -e
# switch to the first available virtual terminal and ask for root password,
#   and if successful, run the given command
if openvt -sw -- /bin/sh /usr/localshare/su-chkpasswd.sh; then
  $@
else
  echo "authentication failure"
fi
' > /usr/local/bin/su
chmod +x /usr/local/bin/su

# lock root account
passwd --lock root

echo -n '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE policyconfig PUBLIC "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
  "http://www.freedesktop.org/standards/PolicyKit/1/policyconfig.dtd">
<policyconfig>
  <action id="comshell.login.su">
    <description>su</description>
    <message>switch users</message>
    <defaults><allow_active>no</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/su</annotate>
  </action>
  <action id="comshell.login.switch-user">
    <description>switch user</description>
    <message>switch user</message>
    <defaults><allow_active>yes</allow_active></defaults>
    <annotate key="org.freedesktop.policykit.exec.path">/bin/sh</annotate>
    <annotate key="org.freedesktop.policykit.exec.argv1">/usr/local/bin/switch-user</annotate>
  </action>
</policyconfig>
' > /usr/share/polkit-1/actions/comshell.login.policy

mkdir -p /etc/polkit-1/localauthority/50-local.d
echo -n '[su]
Identity=unix-group:su
Action=comshell.login.su
ResultActive=yes
' > /etc/polkit-1/localauthority/50-local.d/comshell.login.pkla
