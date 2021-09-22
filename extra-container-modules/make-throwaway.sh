#!/bin/sh

set -eu
umask 022
mkdir -p /_autoserver
docker build -t ctr-script-throwaway - <<\EOF
FROM ubuntu:20.04
RUN mkdir -p /usr/share/ca-certificates /usr/local/share/ca-certificates
RUN apt-get update && apt-get -y dist-upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends wget apt-transport-https ca-certificates && \
sed -i 's#http://\(archive\|security\)\.ubuntu\.com/#https://mirrors.edge.kernel.org/#g' /etc/apt/sources.list && apt-get update && apt-get -y dist-upgrade
RUN set -eu; \
	rm -f /etc/dpkg/dpkg.cfg.d/excludes; \
	export DEBIAN_FRONTEND=noninteractive; \
	dpkg --add-architecture i386; \
	apt-get update; \
	apt-get -y dist-upgrade; \
	apt-get -y install apt-utils busybox-static dbus dialog eatmydata htop openssh-client openssh-server wget
RUN set -eu; export DEBIAN_FRONTEND=noninteractive; \
	apt-get -y install acl apache2 apcalc aspell bc bind9 bind9utils bsdgames build-essential \
	clang dante-server debianutils dnsutils dpkg-dev easy-rsa espeak flac g++ gcc gdb genisoimage gimp \
	git glibc-doc hexedit imagemagick inotify-tools ipcalc ipv6calc iproute2 iputils-ping isolinux \
	lcab lftp libarchive-tools libc6-i386 libnss-myhostname libreoffice libsox-fmt-all lsof ltrace lxde \
	man-db make manpages manpages-dev mc moreutils mplayer mtools net-tools netris nginx-extras ocrad \
	openvpn p7zip-full pavucontrol postfix pulseaudio pv qemu qrencode rsync safe-rm scanmem screen \
	sndfile-programs sndfile-tools socat sox squashfs-tools strace syslinux tcpd tigervnc-standalone-server \
	timidity tmux traceroute translate units valgrind vim-nox vlc vorbis-tools vsftpd wavpack x11vnc \
	xserver-xephyr zile wireshark wine mono-complete; \
	rm -rf /etc/ssh /etc/bind/rndc.key /etc/ssl/private /etc/ssl/certs/ssl-cert-snakeoil.pem /var/lib/polkit-1/localauthority && ln -s /run/tb-config/ssh /etc/ssh; \
	mv /usr/local /usr/_local && mkdir /usr/local && rm /etc/ssl/certs/ca-certificates.crt && dpkg-reconfigure ca-certificates
RUN set -eu; export DEBIAN_FRONTEND=noninteractive; apt-get -y install imagemagick; units_cur
EOF
docker run --rm -v /_autoserver/_ctr-script-build-output_4/throwaway:/build_out --entrypoint= -u root ctr-script-throwaway /bin/sh -c 'tar c /bin /etc /lib /lib64 /sbin /usr /var > /build_out/rootfs.tar'

. ./common
write_system 4 100000
do_build_output 4 55564
