#!/bin/sh

unshare -r -m --propagation=slave sh <<\EOF
set -eu
mount -t tmpfs -o mode=0700 none /tmp
M_TMPDIR="$(mktemp -d)"
chmod 755 "$M_TMPDIR"
bsdtar -xC "$M_TMPDIR" --no-acls --no-same-owner --no-same-permissions --no-xattrs --exclude 'var/lib/apt/lists/*' -f "rootfs.tar.gz"
(
set -eu
cd "$M_TMPDIR"
for x in etc usr usr/lib usr/src usr/share usr/share/man usr/share/doc; do
	[ "directory" = "$(stat -c%F "$x")" ]
done
rm -f etc/resolv.conf etc/hosts etc/hostname etc/inittab
: > etc/resolv.conf
: > etc/hosts
: > etc/hostname
: > etc/inittab
rm -rf usr/lib/modules usr/src/linux-headers-*
ln -s /__autoserver__/kernel_modules/modules usr/lib/modules
find usr/share/doc usr/share/man -type f -name '*.gz' -exec gunzip -- {} +
)
# bsdtar -xC "$M_TMPDIR" --no-acls --no-same-owner --no-same-permissions --no-xattrs --chroot -f "../linux-builder/build_root/linux-output.tar.gz" lib/modules
# mv "$M_TMPDIR/lib/modules" "$M_TMPDIR/usr/lib/"
mksquashfs "$M_TMPDIR" system.img -noappend -comp xz -b 1048576 -Xdict-size 50%
EOF
