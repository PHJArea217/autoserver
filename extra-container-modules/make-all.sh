#!/bin/sh

set -eu
case "$0" in
	*/*)
		cd "${0%/*}"
		;;
esac

mkdir -p /_autoserver_out/extra_container_modules

sh ../rootfs-builder/make-rootfs.sh </dev/null
[ "regular file" = "`stat -c%F /_autoserver/system-img/rootfs.tar.gz`" ]
ln -s /_autoserver/system-img/rootfs.tar.gz ../rootfs-builder/rootfs.tar.gz

docker rmi autoserver-rootfs

T_ARCH=amd64 sh make-container.sh </dev/null
cp /_autoserver/_ctr-scripts-build-output_1/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_1_amd64.sqf
rm -rf /_autoserver/_ctr-scripts-build-output_1

docker rmi ctr-script-generic

T_ARCH=arm32 sh make-container.sh </dev/null
cp /_autoserver/_ctr-scripts-build-output_5/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_1_arm32.sqf
rm -rf /_autoserver/_ctr-scripts-build-output_5

docker rmi ctr-script-generic

T_ARCH=arm64 sh make-container.sh </dev/null
cp /_autoserver/_ctr-scripts-build-output_6/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_1_arm64.sqf
rm -rf /_autoserver/_ctr-scripts-build-output_6

docker rmi ctr-script-generic

sh make-container-2.sh </dev/null
cp /_autoserver/_ctr-scripts-build-output_2/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_2_amd64.sqf
rm -rf /_autoserver/_ctr-scripts-build-output_2

docker rmi ctr-script2-mediawiki ctr-script2-node

sh make-throwaway.sh </dev/null
cp /_autoserver/_ctr-scripts-build-output_4/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_4_amd64.sqf
rm -rf /_autoserver/_ctr-scripts-build-output_4

docker rmi ctr-script-throwaway
