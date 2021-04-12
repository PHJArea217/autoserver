#!/bin/sh

set -eux

if [ "$1" = "quick-brown-fox" ]; then
	:
else
	echo >&2 This script was not meant to be run directly.
	exit 1
fi

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

[ -r /build_root_r/env ] && . /build_root_r/env

mkdir -p /build_tmp

cd /build_tmp

git clone /build_root_r/container-scripts ctr-scripts_x86
git clone /build_root_r/socketbox socketbox_x86
git clone /build_root_r/container-scripts ctr-scripts_arm32
git clone /build_root_r/socketbox socketbox_arm32
git clone /build_root_r/container-scripts ctr-scripts_arm
git clone /build_root_r/socketbox socketbox_arm

make -C ctr-scripts_x86/ctrtool -j 4 4>&- 3>&-
make -C ctr-scripts_x86/bind-anywhere -j 4 4>&- 3>&-
make -C socketbox_x86 -j 4 4>&- 3>&-

make -C ctr-scripts_arm/ctrtool CROSS_COMPILE=aarch64-linux-gnu- CC=aarch64-linux-gnu-gcc AR=aarch64-linux-gnu-ar ARCH=aarch64 CFLAGS='-O3 -g -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fPIC -fPIE' -j 4 4>&- 3>&-
make -C ctr-scripts_arm/bind-anywhere CC=aarch64-linux-gnu-gcc AR=aarch64-linux-gnu-ar CFLAGS='-O3 -g -fstack-protector-strong -fvisibility=hidden -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fPIC' -j 4 4>&- 3>&-
make -C socketbox_arm CC=aarch64-linux-gnu-gcc AR=aarch64-linux-gnu-ar CFLAGS='-Wall -O2 -fstack-protector-strong -fvisibility=hidden -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fPIC' -j 4 4>&- 3>&-

make -C ctr-scripts_arm32/ctrtool CROSS_COMPILE=arm-linux-gnueabihf- CC=arm-linux-gnueabihf-gcc AR=arm-linux-gnueabihf-ar ARCH=armhf CCLDFLAGS_S='-Wl,-z,relro,-z,now -static' CFLAGS='-O3 -g -fstack-protector-strong -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fPIC -fPIE' -j 4 4>&- 3>&-
make -C ctr-scripts_arm32/bind-anywhere CC=arm-linux-gnueabihf-gcc AR=arm-linux-gnueabihf-ar CFLAGS='-O3 -g -fstack-protector-strong -fvisibility=hidden -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fPIC' -j 4 4>&- 3>&-
make -C socketbox_arm32 CC=arm-linux-gnueabihf-gcc AR=arm-linux-gnueabihf-ar CFLAGS='-Wall -O2 -fstack-protector-strong -fvisibility=hidden -fstack-clash-protection -D_FORTIFY_SOURCE=2 -fPIC' -j 4 4>&- 3>&-

mkdir /bin_out_a /bin_out_a/amd64 /bin_out_a/aarch64 /bin_out_a/arm32

strip -o /bin_out_a/amd64/ctrtool ctr-scripts_x86/ctrtool/ctrtool
strip -o /bin_out_a/amd64/ctrtool-static ctr-scripts_x86/ctrtool/ctrtool-static
strip -o /bin_out_a/amd64/bind-anywhere.so ctr-scripts_x86/bind-anywhere/bind-anywhere.so

aarch64-linux-gnu-strip -o /bin_out_a/aarch64/ctrtool ctr-scripts_arm/ctrtool/ctrtool
aarch64-linux-gnu-strip -o /bin_out_a/aarch64/ctrtool-static ctr-scripts_arm/ctrtool/ctrtool-static
aarch64-linux-gnu-strip -o /bin_out_a/aarch64/bind-anywhere.so ctr-scripts_arm/bind-anywhere/bind-anywhere.so

arm-linux-gnueabihf-strip -o /bin_out_a/arm32/ctrtool ctr-scripts_arm32/ctrtool/ctrtool
arm-linux-gnueabihf-strip -o /bin_out_a/arm32/ctrtool-static ctr-scripts_arm32/ctrtool/ctrtool-static
arm-linux-gnueabihf-strip -o /bin_out_a/arm32/bind-anywhere.so ctr-scripts_arm32/bind-anywhere/bind-anywhere.so

for x in libsocketbox-preload.so socket-query socketbox socketbox-inetd socketbox-inetd-p socketbox-relay send-receive-fd; do
	strip -o /bin_out_a/amd64/"$x" socketbox_x86/"$x"
	aarch64-linux-gnu-strip -o /bin_out_a/aarch64/"$x" socketbox_arm/"$x"
	arm-linux-gnueabihf-strip -o /bin_out_a/arm32/"$x" socketbox_arm32/"$x"
done

chmod -x /bin_out_a/amd64/*.so /bin_out_a/aarch64/*.so /bin_out_a/arm32/*.so

bsdtar -cz -C /bin_out_a -f - . > /dev/fd/4

exec 4>&-

cd /
rm -rf /build_tmp /bin_out_a
mkdir /build_tmp

cp -ar /build_root_r/busybox /build_tmp/busybox-d-amd64
cp -ar /build_root_r/busybox /build_tmp/busybox-d-aarch64
cp -ar /build_root_r/busybox /build_tmp/busybox-d-arm32
cp -ar /build_root_r/busybox /build_tmp/busybox-s-amd64
cp -ar /build_root_r/busybox /build_tmp/busybox-s-aarch64
cp -ar /build_root_r/busybox /build_tmp/busybox-s-arm32

cd /build_tmp
cat > busybox_config_common <<\EOF
CONFIG_BASH_IS_ASH=y
CONFIG_BBCONFIG=y
CONFIG_EXTRA_LDFLAGS="-z relro -z now"
CONFIG_FEATURE_PREFER_APPLETS=y
CONFIG_FEATURE_PREFER_IPV4_ADDRESS=n
CONFIG_FEATURE_SH_EXTRA_QUIET=n
CONFIG_FEATURE_SH_STANDALONE=y
CONFIG_FEATURE_UNIX_LOCAL=y
CONFIG_RFKILL=y
CONFIG_VERBOSE_RESOLUTION_ERRORS=y
EOF

cat busybox_config_common - > busybox-d-amd64/.config <<\EOF
CONFIG_EXTRA_CFLAGS="-fstack-protector-strong -D_FORTIFY_SOURCE=2 -fcf-protection=full -fstack-clash-protection"
CONFIG_PIE=y
EOF
cat busybox_config_common - > busybox-s-amd64/.config <<\EOF
CONFIG_EXTRA_CFLAGS="-static-pie -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fcf-protection=full -fstack-clash-protection"
EOF
cat busybox_config_common - > busybox-d-aarch64/.config <<\EOF
# CONFIG_CROSS_COMPILE="aarch64-linux-gnu-"
CONFIG_EXTRA_CFLAGS="-fstack-protector-strong -D_FORTIFY_SOURCE=2 -fstack-clash-protection"
CONFIG_PIE=y
EOF
cat busybox_config_common - > busybox-s-aarch64/.config <<\EOF
# CONFIG_CROSS_COMPILE="aarch64-linux-gnu-"
CONFIG_EXTRA_CFLAGS="-static-pie -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fstack-clash-protection"
EOF

cat busybox_config_common - > busybox-d-arm32/.config <<\EOF
CONFIG_EXTRA_CFLAGS="-fstack-protector-strong -D_FORTIFY_SOURCE=2 -fstack-clash-protection"
CONFIG_PIE=y
EOF
cat busybox_config_common - > busybox-s-arm32/.config <<\EOF
CONFIG_EXTRA_CFLAGS="-static -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fstack-clash-protection"
EOF

yes "" | make -C busybox-d-amd64 oldconfig 3>&-
yes "" | make -C busybox-s-amd64 oldconfig 3>&-
yes "" | make -C busybox-d-aarch64 CROSS_COMPILE=aarch64-linux-gnu- oldconfig 3>&-
yes "" | make -C busybox-s-aarch64 CROSS_COMPILE=aarch64-linux-gnu- oldconfig 3>&-
yes "" | make -C busybox-d-arm32 CROSS_COMPILE=arm-linux-gnueabihf- oldconfig 3>&-
yes "" | make -C busybox-s-arm32 CROSS_COMPILE=arm-linux-gnueabihf- oldconfig 3>&-

make -C busybox-d-amd64 -j 4 3>&-
make -C busybox-s-amd64 -j 4 3>&-
make -C busybox-d-aarch64 CROSS_COMPILE=aarch64-linux-gnu- -j 4 3>&-
make -C busybox-s-aarch64 CROSS_COMPILE=aarch64-linux-gnu- -j 4 3>&-
make -C busybox-d-arm32 CROSS_COMPILE=arm-linux-gnueabihf- -j 4 3>&-
make -C busybox-s-arm32 CROSS_COMPILE=arm-linux-gnueabihf- -j 4 3>&-

mkdir /bin_out_b /bin_out_b/aarch64 /bin_out_b/amd64 /bin_out_b/arm32
cp busybox-d-amd64/busybox /bin_out_b/amd64/busybox-d
cp busybox-s-amd64/busybox /bin_out_b/amd64/busybox-s
cp busybox-d-aarch64/busybox /bin_out_b/aarch64/busybox-d
cp busybox-s-aarch64/busybox /bin_out_b/aarch64/busybox-s
cp busybox-d-arm32/busybox /bin_out_b/arm32/busybox-d
cp busybox-s-arm32/busybox /bin_out_b/arm32/busybox-s

bsdtar -cz -C /bin_out_b -f - . > /dev/fd/3
