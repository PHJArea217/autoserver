#!/bin/sh
set -eu

# Initramfs
T_ARCH_S=""



case "${T_ARCH:=amd64}" in
	aarch64|arm32)
		T_ARCH_S="$T_ARCH"
		ASM_ARCH=arm32
		;;
	amd64)
		T_ARCH_S="amd64"
		ASM_ARCH=i686
		;;
esac

export T_ARCH_S

unshare -r -m --propagation=slave sh -s "$ASM_ARCH" <<\EOF
set -eu
mount -t tmpfs -o mode=0755 none /proc/driver
mkdir -p /proc/driver/initramfs/bin /proc/driver/initramfs/__autoserver__/
bsdtar -x -f - -O "$T_ARCH_S/busybox-s" < ../busybox-builder/__busybox_n.tar.gz > /proc/driver/initramfs/bin/busybox-s
chmod +x /proc/driver/initramfs/bin/busybox-s
cp initramfs-init /proc/driver/initramfs/init
cp vtrgb.S /proc/driver/vtrgb.S
cp vtrgb_arm.S /proc/driver/vtrgb_arm.S
( cd /proc/driver

case "$1" in
	i686)
		x86_64-linux-gnu-as --32 -o vtrgb.o vtrgb.S
		x86_64-linux-gnu-ld -m elf_i386 --omagic -o vtrgb vtrgb.o
		x86_64-linux-gnu-strip -o initramfs/__autoserver__/vtrgb vtrgb
		;;
	arm32)
		arm-linux-gnueabihf-as -o vtrgb_arm.o vtrgb_arm.S
		arm-linux-gnueabihf-ld --omagic -o vtrgb_arm vtrgb_arm.o
		arm-linux-gnueabihf-strip -o initramfs/__autoserver__/vtrgb vtrgb
		;;
esac
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
(cd /proc/driver/initramfs && cpio -0o -H newc -R +0:+0 < ../initramfs_filelist.txt) > initrd
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
mkdir -p __autoserver__ __autoserver-files__/bin __autoserver-files__
cp -r /proc/self/fd/3/include __autoserver-files__
bsdtar -xC __autoserver-files__/bin --strip-components 2 --no-fflags -f - "$T_ARCH_S/ctrtool*" < /proc/self/fd/3/../busybox-builder/__ctr-scripts.tar.gz
bsdtar -xC __autoserver-files__/bin --strip-components 2 --no-fflags -f - "$T_ARCH_S" < /proc/self/fd/3/../busybox-builder/__busybox_n.tar.gz
cp /proc/self/fd/3/../busybox-builder/__c_sources.tar.gz __autoserver-files__/sources.tar.gz
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
ln -s busybox static/ln
ln -s ../__autoserver-files__/bin/ctrtool __autoserver__/ctrtool
ln -s ../kernel_modules __autoserver__/kernel_modules
for x in container-launcher container-rootfs-mount debug_shell mini-init mount_seq reset_cgroup simple-renameat2 set_fds; do
	ln -s ctrtool __autoserver__/"$x"
	ln -s ctrtool __autoserver-files__/bin/"$x"
done
bsdtar -cJf - --uid 0 --gid 0 . > /proc/self/fd/3/rootfs/0_base.txz
EOF
