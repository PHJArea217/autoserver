#!/bin/sh
set -euC
mkdir -p _out/kernel/x86/microcode
cat /lib/firmware/amd-ucode/*.bin > _out/kernel/x86/microcode/AuthenticAMD.bin
cd _out
find -print0 | cpio -0 -o -H newc > ../ucode_amd.img
