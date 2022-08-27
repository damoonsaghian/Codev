apt-get install --no-install-recommends --yes dbus-user-session kbd pkexec
# kbd is needed for its chvt and openvt

echo -n '#!/usr/bin/pkexec /bin/sh
navt=$(fgconsole --next-available)
systemctl start getty@tty"$navt".service
loginctl lock-session
chvt "$navt"
echo "$navt" > /tmp/su-vt
' > /usr/local/bin/switch-user
chmod +x /usr/local/bin/switch-user

# when a keyboard is connected, disable others, lock the session (if any), run "switch-user"
# since password prompts only accept keyboard input, this is not necessary for headsets
# this has two benefits:
# , when you want to login you are sure that it's the login screen (not a fake one created by another user)
# , others can't access your session using an extra keyboard

echo -n '# run this script if running from tty1, or if put here by "switch-user"
if [ "$(tty)" = "/dev/tty1" ] || [ "$(fgconsole)" = "$(cat /tmp/su-vt)" ]; then
  # if a user session is already running, switch to it, unlock it, and exit
  loginctl show-user "$USER" --value --property=Sessions | {
    read current_session previous_session rest
    previous_tty=$(loginctl show-session $previous_session --value --property=TTY)
    current_tty=$(tty)
    current_tty=${current_tty##*/}
    if [ -n $previous_session ] && [ $current_tty != $previous_tty ]; then
      loginctl activate $previous_session &&
      loginctl unlock-session $previous_session
      systemctl stop getty@$current_tty.service
      exit
    fi
  }
  [ $(id -u) = 0 ] || exec sway -c /usr/local/share/sway.conf
fi
' > /etc/profile.d/login-manager.sh

groupadd su
# add the first user to su group
usermod -aG su "$(id -nu 1000)"

echo -n '#!/usr/bin/pkexec /bin/sh
set -e
# switch to the first available virtual terminal and ask for root password
# openvt -sw ...
# if the password is correct run $@
# getent shadow root | cut -d: -f2 | cut -c2-
# https://unix.stackexchange.com/questions/329878/check-users-password-with-a-shell-script
# https://unix.stackexchange.com/questions/21705/how-to-check-password-with-linux
# https://askubuntu.com/questions/611580/how-to-check-the-password-entered-is-a-valid-password-for-this-user
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
