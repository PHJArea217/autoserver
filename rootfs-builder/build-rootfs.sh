#!/bin/sh

unshare -r -m --propagation=slave sh <<\EOF
mount -t tmpfs -o mode=0700 none /tmp
M_TMPDIR="$(mktemp -d)"
chmod 755 "$M_TMPDIR"
bsdtar -xC "$M_TMPDIR" --no-acls --no-same-owner --no-same-permissions --no-xattrs --chroot -f "rootfs.tar.gz"
(
cd "$M_TMPDIR"
rm -f etc/resolv.conf etc/hosts etc/hostname etc/inittab
: > etc/resolv.conf
: > etc/hosts
: > etc/hostname
: > etc/inittab
rm -rf usr/lib/modules usr/src/linux-headers-*
ln -s /__autoserver__/kernel_modules/modules usr/lib/modules
)
# bsdtar -xC "$M_TMPDIR" --no-acls --no-same-owner --no-same-permissions --no-xattrs --chroot -f "../linux-builder/build_root/linux-output.tar.gz" lib/modules
mv "$M_TMPDIR/lib/modules" "$M_TMPDIR/usr/lib/"
mksquashfs "$M_TMPDIR" system.img -noappend -comp gzip -b 1048576
EOF
