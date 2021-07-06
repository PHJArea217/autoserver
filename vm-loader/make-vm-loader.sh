#!/bin/sh
set -eu
mkdir -p _tmp/root_modules
tar -c -C data/ --owner=0 --group=0 . > _tmp/root_modules/vm-loader.tar
bash -c 'set -euo pipefail
sha256sum _tmp/root_modules/vm-loader.tar | head -c 64 > _tmp/root_modules/vm-loader.manifest
( cd _tmp; find | cpio -o -H newc) | xz -ce --check=crc32 | cat ../initramfs-builder/initrd.xz - > initrd-vm-loader.xz'
