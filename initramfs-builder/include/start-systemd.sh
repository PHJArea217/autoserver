#!/bin/sh
set -eu
if [ ! -d /run/c-systemd/rw ]; then
	mkdir -p /run/c-systemd/rw
	mount -t tmpfs -o mode=0700 none /run/c-systemd/rw
	mkdir /run/c-systemd/rw/rw /run/c-systemd/rw/work
fi

printf '%s/__systemd\0' /sys/fs/cgroup/* | xargs -0 mkdir -p --

/__autoserver__/ctrtool reset_cgroup -p __systemd -s -u -a cpuacct,net_cls,net_prio,autoserver_user -- unshare --propagation=slave -m -C -i -u sh -s <<\EOF
set -eu
# /__autoserver__/ctrtool rootfs-mount -o root_link_opts=usr_ro -o root_symlink_usr=1 /proc/driver
mount -t tmpfs -o mode=0755 none /proc/driver
cd /proc/driver

for x in bin lib lib64 lib32 libx32 sbin; do
	ln -s "usr/$x"
done
ln -s _fsroot_ro/usr usr

mkdir -m 700 dev proc sys host
mkdir _fsroot_ro _fsroot_rw host/old_root run run/shm
mkdir -m 1777 tmp
mount -t overlay -o upperdir=/run/c-systemd/rw/rw,workdir=/run/c-systemd/rw/work,lowerdir=/rofs_root none _fsroot_ro
hostname autoserver-2
pivot_root . host/old_root
hash -r
exec unshare -p --fork /lib/systemd/systemd
EOF
