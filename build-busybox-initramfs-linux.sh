#!/bin/sh

set -eu
case "$0" in
	*/*)
		cd "${0%/*}"
		;;
esac
sh -c 'cd busybox-builder && exec sh build-busybox.sh' </dev/null
sh -c 'cd initramfs-builder && exec sh build-initramfs.sh' </dev/null
if ! [ "alt" = "$1" ]; then
	sh -c 'cd linux-builder && exec sh build-linux.sh' </dev/null
fi
rm -rf linux-builder/build_root
