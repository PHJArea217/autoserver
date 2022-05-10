#!/bin/sh

set -eu
umask 022
mkdir -p /_autoserver
docker build -t ctr-script-build - <<\EOF
FROM debian:11
RUN mkdir -p /usr/share/ca-certificates /usr/local/share/ca-certificates
RUN apt-get update && apt-get -y dist-upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends wget apt-transport-https ca-certificates && \
sed -i 's# http://# https://#g' /etc/apt/sources.list && apt-get update && apt-get -y dist-upgrade
RUN set -eu; \
	rm -f /etc/dpkg/dpkg.cfg.d/excludes; \
	export DEBIAN_FRONTEND=noninteractive; \
	apt-get update; \
	apt-get -y dist-upgrade; \
	apt-get -y install apt-utils busybox-static dialog eatmydata htop iproute2 net-tools wget
RUN set -eu; export DEBIAN_FRONTEND=noninteractive; \
	apt-get -y install git libarchive-tools p7zip-full build-essential gcc gcc-aarch64-linux-gnu make cmake flex bison file bc \
	cpio libssl-dev libncurses-dev python3 python3-dev python3-distutils python3-setuptools swig u-boot-tools device-tree-compiler \
	gcc-arm-none-eabi libnewlib-arm-none-eabi libstdc++-arm-none-eabi-newlib; \
	rm -rf /etc/ssh /etc/bind/rndc.key /etc/ssl/private /etc/ssl/certs/ssl-cert-snakeoil.pem /var/lib/polkit-1/localauthority; \
	mv /usr/local /usr/_local && mkdir /usr/local && rm /etc/ssl/certs/ca-certificates.crt && dpkg-reconfigure ca-certificates
RUN set -eu; mkdir -p /usr/src; cd /usr/src \
	git clone https://github.com/raspberrypi/pico-sdk \
	git -C pico-sdk submodule init \
	git clone https://github.com/raspberrypi/pico-examples
EOF
docker run --rm -v /_autoserver/_ctr-script-build-output_9/build_ctr:/build_out --entrypoint= -u root ctr-script-build /bin/sh -c 'tar c /bin /etc /lib /lib64 /sbin /usr /var > /build_out/rootfs.tar'

. ./common
write_system 9 100000
do_build_output 9 55569
