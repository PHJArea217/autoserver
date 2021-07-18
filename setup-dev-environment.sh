#!/bin/sh

set -euC

if [ ! -d /run/live ]; then
	echo This script is meant to run only on the Debian Live DVD.
	exit 1
fi

if [ ! -d /autoserver_disk ]; then
	echo Please create a blank virtual HDD, format it as ext4,
	echo and then mount it on /autoserver_disk.
	exit 1
fi
mkdir -p /autoserver_disk/_autoserver /autoserver_disk/_out /autoserver_disk/docker /var/lib/docker /_autoserver /_autoserver_out /etc/docker
mount --bind /autoserver_disk/docker /var/lib/docker
mount --bind /autoserver_disk/_out /_autoserver_out
mount --bind /autoserver_disk/_autoserver /_autoserver
printf '{"userns-remap": "default"}' > /etc/docker/daemon.json
cat > /etc/apt/sources.list.tmp <<\EOF
deb https://deb.debian.org/debian bullseye main contrib
deb-src https://deb.debian.org/debian bullseye main contrib
EOF
mv /etc/apt/sources.list.tmp /etc/apt/sources.list

apt-get update
apt-get -y dist-upgrade

apt-get -y install git gcc gcc-i686-linux-gnu gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf squashfs-tools \
	libarchive-tools docker.io make bison flex build-essential busybox-static libelf-dev libssl-dev bc
