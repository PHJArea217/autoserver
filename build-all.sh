#!/bin/sh
set -eu

run_unpriv() {
	setpriv --reuid="$SUDO_UID" --regid="$SUDO_GID" --init-groups "$@"
}

run_unpriv sh build-busybox-initramfs-linux.sh
sh extra-container-modules/make-all.sh
run_unpriv sh -c 'cd rootfs-builder && exec sh build-rootfs.sh'
sh install-files.sh
