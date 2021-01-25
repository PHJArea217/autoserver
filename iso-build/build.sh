#!/bin/sh
set -eu
mkdir -p output/autosvr
cp ../linux-builder/build_root/arch/x86/boot/bzImage output/vmlinuz
xz -ce ../linux-builder/build_root/System.map > output/sysmap.xz
cp ../initramfs-builder/initrd.gz output/
cp /usr/lib/ISOLINUX/isolinux.bin output/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 output/
cp syslinux.cfg output/
cp -l --reflink=auto ../rootfs-builder/system.img output/autosvr/
cp -l --reflink=auto ../linux-builder/k_mod.img output/autosvr/

cd output
genisoimage -o ../autoserver.iso -b isolinux.bin -boot-info-table -no-emul-boot -boot-load-size 4 .
