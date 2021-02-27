#!/bin/sh
set -eu

# Initramfs
unshare -r -m --propagation=slave <<\EOF
set -eu
mount -t tmpfs -o mode=0755 none /proc/driver
mkdir -p /proc/driver/initramfs/bin /proc/driver/initramfs/__autoserver__/
bsdtar -xC /proc/driver/initramfs/bin --strip-components 1 --no-fflags -f - output_b/busybox-s < ../busybox-builder/busybox.tar.gz
cp initramfs-init /proc/driver/initramfs/init
cp vtrgb.S /proc/driver/vtrgb.S
( cd /proc/driver
as --32 -o vtrgb.o vtrgb.S
ld -m elf_i386 --omagic -o vtrgb vtrgb.o
strip -o initramfs/__autoserver__/vtrgb vtrgb
)
( cd /proc/driver/initramfs
mkdir boot_disk dev etc new_root proc rofs_root sys
ln -s usr/lib lib
ln -s usr/lib64 lib64
ln -s usr/lib32 lib32
ln -s usr/libx32 libx32
ln -s rofs_root/usr usr
mv bin/busybox-s bin/busybox
for x in insmod ln mkdir mount printf sh sleep umount; do
	ln -s busybox bin/"$x"
done
ln -s /rofs_root/etc/alternatives etc/alternatives
find -print0 > ../initramfs_filelist.txt
)
(cd /proc/driver/initramfs && cpio -0o -H newc < ../initramfs_filelist.txt) > initrd
EOF

xz -2ec --check=crc32 initrd > initrd.xz
rm -f initrd


# Base rootfs
mkdir -p rootfs
unshare -r -m --propagation=slave <<\EOF
set -eu
mount -t tmpfs -o mode=0755 none /proc/driver
exec 3<.
cd /proc/driver
mkdir rootfs
cd rootfs
mkdir -p __autoserver__ __autoserver-files__/bin __autoserver-files__/src
cp -r /proc/self/fd/3/include __autoserver-files__
bsdtar -xC __autoserver-files__/bin --strip-components 1 --no-fflags -f - output_b < /proc/self/fd/3/../busybox-builder/busybox.tar.gz
bsdtar -xC __autoserver-files__/src --strip-components 1 --no-fflags -f - output_s < /proc/self/fd/3/../busybox-builder/busybox.tar.gz
mkdir -p static etc/ld.so.conf.d
ln -s usr/bin bin
ln -s usr/lib lib
ln -s usr/lib64 lib64
ln -s usr/lib32 lib32
ln -s usr/libx32 libx32
ln -s usr/sbin sbin
ln -s rofs_root/usr usr
ln -s ../__autoserver-files__/include/ld.so.conf etc/ld.so.conf
ln -s ../__autoserver-files__/include/init_stage3_example __autoserver__/init_stage3_example
ln -s ../__autoserver-files__/include/start-systemd.sh __autoserver__/start-systemd.sh
ln -s ../__autoserver-files__/include/stage3_include __autoserver__/stage3_include
ln -s ../__autoserver-files__/bin/busybox-d __autoserver__/busybox-d
ln -s ../__autoserver-files__/bin/busybox-s static/busybox
ln -s busybox static/sh
ln -s ../__autoserver-files__/bin/ctrtool __autoserver__/ctrtool
ln -s ../kernel_modules __autoserver__/kernel_modules
for x in container-launcher container-rootfs-mount mini-init mount_seq reset_cgroup simple-renameat2; do
	ln -s ctrtool __autoserver__/"$x"
	ln -s ctrtool __autoserver-files__/bin/"$x"
done
bsdtar -cJf - . > /proc/self/fd/3/rootfs/0_base.txz
EOF
