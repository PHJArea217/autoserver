#!/bin/sh

set -eu

KERN_VERSION=5.12.12
KERN_SHASUM=212ab2bc3d9616f48069f506196a0d1fa7f54db1593a76dccccfa23bdfaa3ea8
mkdir -p build_root/kernel-output
[ ! -f linux.tar.xz ] && wget -O linux.tar.xz https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-"$KERN_VERSION".tar.xz
if sha256sum linux.tar.xz | grep -q "^$KERN_SHASUM "; then
	:
else
	echo >&2 Incorrect checksum
	exit 1
fi
[ ! -f build_root/.config ] && bsdtar -xf linux.tar.xz -C build_root --strip-components 1
cp linux_config build_root/.config

script -qc 'unshare -r -m -i -u -p -n --fork --mount-proc --propagation=slave sh -c "exec /bin/sh <&3 3<&-"' /dev/null 3<<\EOF
set -eux

hostname autoserver
ip link set lo up
mount -t tmpfs -o mode=0755 none /proc/driver
mkdir /proc/driver/build_root
mount --rbind build_root /proc/driver/build_root
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
exec sh -c 'cd /build_root && make olddefconfig && make -j 5 && make INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=/build_root/kernel-output modules_install && \
make INSTALL_HDR_PATH=/build_root/kernel-output/usr headers_install && rm -f kernel-output/lib/modules/*/source kernel-output/lib/modules/*/build && \
mksquashfs /build_root/kernel-output/usr /build_root/kernel-output/lib/modules /build_root/kernel-output/k_mod.img -comp xz -b 1048576 -Xdict-size 100% -Xbcj x86 -noappend -all-root'
EOF
