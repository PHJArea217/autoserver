#!/bin/sh
set -eu
unshare -r -m --propagation=slave <<\EOF
set -eu
mount -t tmpfs -o mode=0755 none /proc/driver
mkdir -p /proc/driver/initramfs/bin /proc/driver/initramfs/__autoserver__/kernel_modules
bsdtar -xC /proc/driver/initramfs/__autoserver__/ --strip-components 1 --no-fflags -f - < ../busybox-builder/busybox.tar.gz
cp initramfs-init2 /proc/driver/initramfs/init_stage2
cp initramfs-init /proc/driver/initramfs/init
( cd /proc/driver/initramfs
mkdir boot_disk dev etc new_root proc rofs_root sys
ln -s usr/lib lib
ln -s usr/lib64 lib64
ln -s usr/lib32 lib32
ln -s usr/libx32 libx32
ln -s rofs_root/usr usr
mv __autoserver__/busybox-s bin/busybox
ln -s busybox bin/sh
# ln -s /rofs_root/etc/alternatives etc/alternatives
find -print0 > ../initramfs_filelist.txt
)
(cd /proc/driver/initramfs && cpio -0o -H newc < ../initramfs_filelist.txt) > initrd
EOF

gzip -9 initrd
