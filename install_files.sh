#!/bin/sh
set -eu

safe_cp() {
	if ! [ "regular file" = "$(stat -c%F "$1")" ]; then
		printf '%s is not a regular file\n' "$1"
		exit 1
	fi
	cp "$@"
}

mkdir -p /_autoserver_out/as_boot /_autoserver_out/autosvr
if ! [ "alt" = "$1" ]; then
	safe_cp linux-builder/build_out/vmlinuz /_autoserver_out/as_boot/vmlinuz
	safe_cp linux-builder/build_out/k_mod.img /_autoserver_out/autosvr/k_mod.img
	safe_cp linux-builder/build_out/sysmap.xz /_autoserver_out/as_boot/sysmap.xz
	safe_cp iso-build/syslinux.cfg /_autoserver_out/as_boot/syslinux.cfg
fi
safe_cp initramfs-builder/initrd.xz /_autoserver_out/as_boot/initrd.xz
safe_cp initramfs-builder/rootfs/0_base.txz /_autoserver_out/autosvr/0_base.txz

if ! [ "alt" = "$1" ]; then
	safe_cp rootfs-builder/system.img /_autoserver_out/autosvr/system.img
fi

sha256sum -b /_autoserver_out/*/* > /_autoserver_out/sha256sums.txt
