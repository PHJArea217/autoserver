#!/bin/sh
set -eu

run_unpriv() {
	setpriv --reuid="$SUDO_UID" --regid="$SUDO_GID" --init-groups "$@"
}

exec </dev/null
run_unpriv sh build-busybox-initramfs-linux.sh main
sh extra-container-modules/make-all.sh main
run_unpriv sh -c 'cd rootfs-builder && exec sh build-rootfs.sh'
sh install_files.sh main

# For audit/debug purposes
docker images
date
