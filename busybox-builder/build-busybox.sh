#!/bin/sh

set -eu

bb_version='1.36.0'
bb_sha512='1c203b6408154c4a44b8b126b49f9a131614d8fe48656992fccf3c315d56f54335bb1f8e6a1d4202b59d01152fd886277f7f13935c058d9bf9e07f1ee783a2da'

if [ ! -f __busybox.tar.bz2 ]; then
	wget -O __busybox.tar.bz2.tmp https://www.busybox.net/downloads/busybox-"$bb_version".tar.bz2
	sha512sum __busybox.tar.bz2.tmp | grep -q "^$bb_sha512 "
	mv __busybox.tar.bz2.tmp __busybox.tar.bz2
fi

mkdir -p __build_root_r/busybox
if [ ! -f __build_root_r/_busybox_done ]; then
	bsdtar -xf __busybox.tar.bz2 -C __build_root_r/busybox --strip-components 1
fi

touch __build_root_r/_busybox_done

# If you're not part of the peterjin.org network, change the second line below to https://git2.peterjin.org to use our public Git server instead.
sh -c 'set -eu; cd __build_root_r; for x in autoserver autoserver-appliances socketbox container-scripts python-socketbox ctrtool-containers ctrtool-config_tars socket-enhancer universal-relay; do [ ! -d "$x"/refs ] && git clone --mirror "$1"/"$x"; done; exit 0' _ \
	/autoserver_repos

for x in __build_root_r/*.git; do mv "$x" "${x%%.git}"; done
bsdtar -czf __c_sources.tar.gz --uid 0 --gid 0 \
	__build_root_r/autoserver \
	__build_root_r/autoserver-appliances \
	__build_root_r/container-scripts \
	__build_root_r/ctrtool-containers \
	__build_root_r/ctrtool-config_tars \
	__build_root_r/socket-enhancer \
	__build_root_r/universal-relay \
	__build_root_r/socketbox

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
busybox pivot_root . .
busybox umount -l .
if [ "1" = "${DO_SHELL:-0}" ]; then
	exec sh -c 'exec /bin/bash </dev/tty'
	exit 1
fi
exec setpriv --bounding-set=-all env - sh /build-busybox_s.sh quick-brown-fox </dev/null
EOF
mv __busybox_n.tar.gz.tmp __busybox_n.tar.gz
mv __ctr-scripts.tar.gz.tmp __ctr-scripts.tar.gz
