#!/bin/sh
set -eu

run_unpriv() {
	setpriv --reuid="$SUDO_UID" --regid="$SUDO_GID" --init-groups "$@"
}

exec </dev/null
run_unpriv sh build-busybox-initramfs-linux.sh alt
sh extra-container-modules/make-all.sh alt
sh install_files.sh alt

# For audit/debug purposes
docker images
date
