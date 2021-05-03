#!/bin/sh

set -eu

bb_sha512=20f8f5197c5cbc8b244f69d82d6628066296c7306a9736ee1344cb555882854412cf7f264490f9a735251c139b9621004f48e972d06ef2623a3c99278f8e765a

if [ ! -f __busybox.tar.bz2 ]; then
	wget -O __busybox.tar.bz2.tmp https://www.busybox.net/downloads/busybox-1.33.0.tar.bz2
	sha512sum __busybox.tar.bz2.tmp | grep -q "^$bb_sha512 "
	mv __busybox.tar.bz2.tmp __busybox.tar.bz2
fi

mkdir -p __build_root_r/busybox
if [ ! -f __build_root_r/_busybox_done ]; then
	bsdtar -xf __busybox.tar.bz2 -C __build_root_r/busybox --strip-components 1
fi

touch __build_root_r/_busybox_done

sh -c 'set -eu; cd __build_root_r; [ ! -d container-scripts/.git ] && git clone --no-checkout https://git.internal.peterjin.org/_/container-scripts; [ ! -d socketbox/.git ] && git clone --no-checkout https://git.internal.peterjin.org/_/socketbox; exit 0'

bsdtar -czf __c_sources.tar.gz --uid 0 --gid 0 __build_root_r/container-scripts __build_root_r/socketbox

script -c 'exec unshare -r -m -i -u -p -n --fork --mount-proc --propagation=slave setsid sh' __build.log <<\EOF
set -eux

hostname autoserver
ip link set lo up
mount -t tmpfs -o mode=0755 none /proc/driver
mkdir /proc/driver/build_root_r
mount --rbind -r __build_root_r /proc/driver/build_root_r
cp build-busybox_s.sh /proc/driver/
exec 3>__busybox_n.tar.gz.tmp 4>__ctr-scripts.tar.gz.tmp
cd /proc/driver
mkdir -p dev/pts dev/shm dev/mqueue etc/alternatives proc root run sys tmp usr var
mount --rbind /etc/alternatives etc/alternatives
ln -s usr/bin bin
ln -s usr/lib lib
ln -s usr/lib64 lib64
ln -s usr/sbin sbin
ln -s pts/ptmx dev/ptmx
ln -s /proc/self/fd dev/fd
ln -s fd/0 dev/stdin
ln -s fd/1 dev/stdout
ln -s fd/2 dev/stderr
echo root:x:0:0:root:/root:/bin/bash > etc/passwd
echo root:x:0: > etc/group
mount -t mqueue none dev/mqueue
mount -t devpts -o newinstance,ptmxmode=0666,mode=0600 none dev/pts
for x in full null random tty urandom zero; do
	: > "dev/$x"
	mount --bind "/dev/$x" "dev/$x"
done
mount --rbind -r /usr usr
# mount --rbind /sys sys
mount -t sysfs none sys
mount -t proc none proc

export HOME=/root
pivot_root . .
umount -l .
if [ "1" = "${DO_SHELL:-0}" ]; then
	exec sh -c 'exec /bin/bash </dev/tty'
	exit 1
fi
exec setpriv --bounding-set=-all env - sh -s quick-brown-fox < /build-busybox_s.sh
EOF
mv __busybox_n.tar.gz.tmp __busybox_n.tar.gz
mv __ctr-scripts.tar.gz.tmp __ctr-scripts.tar.gz
