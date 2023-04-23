echo -n '[Match]
Name=en*
#Type=ether
#Name=! veth*
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
[DHCPv4]
RouteMetric=100
[IPv6AcceptRA]
RouteMetric=100
' > /etc/systemd/network/20-ethernet.network

echo -n '[Match]
Name=wl*
#Type=wlan
#WLANInterfaceType=station
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=600
[IPv6AcceptRA]
RouteMetric=600
' > /etc/systemd/network/20-wireless.network
#echo -n '[Match]
#Type=wlan
#WLANInterfaceType=ad-hoc
#[Network]
#LinkLocalAddressing=yes
#' > /etc/systemd/network/80-wifi-adhoc.network
#echo -n '[Match]
#Type=wlan
#WLANInterfaceType=ap
#[Network]
#Address=0.0.0.0/24
#DHCPServer=yes
#IPMasquerade=both
#' > /etc/systemd/network/80-wifi-ap.network
# https://hackaday.io/project/162164/instructions?page=2
# https://raspberrypi.stackexchange.com/questions/133403/configure-usb-wi-fi-dongle-as-stand-alone-access-point-with-systemd-networkd
# https://man.archlinux.org/man/core/systemd/systemd.netdev.5.en

echo -n '[Match]
Name=ib*
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
[DHCPv4]
RouteMetric=200
[IPv6AcceptRA]
RouteMetric=200
' > /etc/systemd/network/20-infiniband.network

echo -n '[Match]
Name=ww*
#Type=wwan
[Network]
DHCP=yes
IPv6PrivacyExtensions=yes
IgnoreCarrierLoss=3s
[DHCPv4]
RouteMetric=700
[IPv6AcceptRA]
RouteMetric=700
' > /etc/systemd/network/20-wwan.network
# https://github.com/systemd/systemd/issues/20370
# https://gitlab.archlinux.org/archlinux/archiso/-/blob/master/configs/releng/airootfs/etc/systemd/network/20-wwan.network
# https://wiki.archlinux.org/title/Mobile_broadband_modem

systemctl enable systemd-networkd

apt-get install -yes systemd-resolved
# https://fedoramagazine.org/systemd-resolved-introduction-to-split-dns/
# https://blogs.gnome.org/mcatanzaro/2020/12/17/understanding-systemd-resolved-split-dns-and-vpn-configuration/
