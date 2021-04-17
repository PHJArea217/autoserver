#!/bin/sh

set -eu
mkdir -p tmp
cat /usr/bin/qemu-arm-static > tmp/qemu-arm-static
chmod +x tmp/qemu-arm-static
cat > tmp/Dockerfile <<\EOF

FROM arm32v7/ubuntu:20.04

COPY qemu-arm-static /usr/bin/
RUN dpkg-divert --add --divert /usr/bin/qemu-arm-static.arm /usr/bin/qemu-arm-static
RUN apt-get update && apt-get install -y ca-certificates
RUN sed -i "s,http://\(archive\|security\)\.ubuntu\.com/,https://mirrors.edge.kernel.org/,g" /etc/apt/sources.list && \
	rm -f /etc/dpkg/dpkg.cfg.d/excludes && apt-get update && apt-get -y --no-install-recommends dist-upgrade
RUN env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends acct acl adduser alsa-utils \
apache2 apcalc apparmor apport apt-utils avahi-daemon avahi-utils bc bind9 bind9utils binfmt-support \
bluez bolt bridge-utils bsdmainutils bsdutils btrfs-progs busybox-initramfs busybox-static ca-certificates cabextract \
cdw colord console-setup-linux containerd cpufrequtils crda cron cups cups-browsed cups-bsd cups-client \
cups-core-drivers cups-daemon cups-filters cups-ipp-utils cups-ppdc cups-server-common curl daemontools dante-server dbus \
debconf debianutils default-jre-headless dhcping dmidecode dmsetup dns-root-data dnsmasq-base \
dnsutils docker.io dosfstools dpkg-dev dvd+rw-tools e2fsprogs easy-rsa eatmydata ebtables ethtool extundelete fdisk \
file fuse gdisk genisoimage geoclue-2.0 geoip-database gettext-base git gitlab-runner gnupg gpg gpgv gpm growisofs hdparm \
hostapd hplip htop initramfs-tools ipcalc ippusbxd iproute2 iptables iptraf-ng iputils-ping ipv6calc \
ipxe-qemu isc-dhcp-client isc-dhcp-server iso-codes iucode-tool iw kbd keyboard-configuration klibc-utils kmod kpartx \
less libarchive-tools libcap2-bin libnss-mdns libnss-myhostname libsox-fmt-all linux-base lm-sensors login lsof \
ltrace man-db manpages manpages-dev mc mdadm mime-support minicom minidlna mlocate moreutils mplayer msr-tools mtools \
mysql-client mysql-server ncurses-bin ncurses-term net-tools netbase netcat-openbsd nftables nginx-common nginx-extras \
ntfs-3g ntp openjdk-13-jre-headless openjdk-11-jre-headless openjdk-8-jre-headless openssh-client openssh-server \
openssh-sftp-server openssl openvpn p7zip-full parted passwd patch pciutils postfix ppp pptp-linux \
printer-driver-gutenprint printer-driver-hpcups printer-driver-postscript-hp procps psmisc pulseaudio \
pulseaudio-utils python python3 qemu qemu-block-extra qemu-system qemu-user qemu-user-static qemu-utils radvd rsyslog \
rtkit runc screen seabios sharutils socat sox squashfs-tools ssh-import-id strace sudo systemd thermald tmux \
traceroute tshark u-boot-tools udev udisks2 usb-modeswitch usbmuxd util-linux vim-nox vsftpd wamerican wget \
wireless-regdb wireless-tools wodim wpasupplicant xserver-xorg-core xserver-xorg-input-all xserver-xorg-video-all xterm xxd xz-utils zsh && \
rm -f /sbin/init /usr/bin/vidir /etc/ssh/ssh_host_*_key* /etc/bind/rndc.key /etc/ssl/private/ssl-cert-snakeoil.key \
	/etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ssl-cert-snakeoil.pem /usr/bin/man /sbin/switch_root && \
	sh -c 'set -Ce; printf %s\\n "#!/bin/sh" :\ \$\{LESS=r\} "export LESS" "exec /static/busybox man "\"\$\@\" \
	> /usr/bin/man' && chmod +x /usr/bin/man && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure ca-certificates

RUN env DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends linux-firmware build-essential make

RUN env DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends isolinux syslinux syslinux-utils syslinux-common \
gpsd gpsd-clients pps-tools bird quagga-core quagga-bgpd conntrack unbound wireguard-tools slirp4netns \
lxc-utils

RUN mv /lib/systemd/system /lib/systemd/system_dist && mkdir /lib/systemd/system
EOF
docker build -t autoserver-arm-rootfs tmp/
docker run --rm -v /docker-buildout/autoserver-arm:/build-output autoserver-arm-rootfs sh -c 'bsdtar -czf - /etc /usr /var > /build-output/rootfs.tar.gz'
