#!/bin/sh

unshare -r -m --propagation=slave sh -s <<\EOF
set -eu

T_ARCH_S=""
case "${T_ARCH:=amd64}" in
	amd64|aarch64|arm32)
		T_ARCH_S="$T_ARCH"
		;;
esac

mount -t tmpfs -o mode=0755 none /proc/driver
mkdir -p /proc/driver/stage2_fs/bin /proc/driver/stage1_fs/__autoserver__/bin /proc/driver/stage1_fs/__autoserver__/src /proc/driver/stage1_fs/__autoserver__/local
tar -xzOf - "./$T_ARCH_S/busybox-s" < ../busybox-builder/__busybox_n.tar.gz > /proc/driver/stage1_fs/__autoserver__/bin/busybox
chmod +x /proc/driver/stage1_fs/__autoserver__/bin/busybox
cat ../busybox-builder/__c_sources.tar.gz > /proc/driver/stage1_fs/__autoserver__/src/c_sources.tar.gz

tar -xzC /proc/driver/stage2_fs/bin --strip-components 2 -f - "./$T_ARCH_S/busybox-s" "./$T_ARCH_S/busybox-d" < ../busybox-builder/__busybox_n.tar.gz
tar -xzC /proc/driver/stage2_fs/bin --strip-components 2 -f - "./$T_ARCH_S/ctrtool" "./$T_ARCH_S/ctrtool-static" < ../busybox-builder/__ctr-scripts.tar.gz

cat include/stage1_init > /proc/driver/stage1_fs/__autoserver__/bin/_init
cat include/local_env_example > /proc/driver/stage1_fs/__autoserver__/local/env
cat include/stage2_init > /proc/driver/stage2_fs/bin/autoserver_init
mkdir /proc/driver/stage2_fs/kernel_modules /proc/driver/stage2_fs/scripts
cat include/stage2_include > /proc/driver/stage2_fs/scripts/stage2_include
cat include/start-inner-system.py > /proc/driver/stage2_fs/scripts/start-inner-system.py
chmod +x /proc/driver/stage2_fs/scripts/stage2_include

ln -s /local_disk/__system__/lib/modules /proc/driver/stage2_fs/kernel_modules

(
set -eu
cd /proc/driver/stage1_fs

mkdir bin dev lib proc sys run sbin __autoserver__/data __autoserver__/new_root
ln -s ../__autoserver__/bin/_init sbin/init
ln -s ../__autoserver__/bin/busybox bin/busybox
ln -s ../__autoserver__/bin/busybox sbin/modprobe
ln -s /__autoserver__/new_root/local_disk/__system__/lib/modules lib/modules
ln -s busybox bin/sh
chmod +x __autoserver__/bin/_init ../stage2_fs/bin/autoserver_init

tar -cJ -C ../stage2_fs --owner=0 --group=0 -f - . > __autoserver__/data/0_root-stub.txz
)

tar -cJ -C /proc/driver/stage1_fs --owner=0 --group=0 -f - . > stub-rootfs.tar.xz
