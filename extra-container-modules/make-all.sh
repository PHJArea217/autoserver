#!/bin/sh

set -eu
case "$0" in
	*/*)
		cd "${0%/*}"
		;;
esac

mkdir -p /_autoserver_out/extra_container_modules

if ! [ "alt" = "$1" ]; then
	sh ../rootfs-builder/make-rootfs.sh </dev/null
	[ "regular file" = "`stat -c%F /_autoserver/system-img/rootfs.tar.gz`" ]
	cp /_autoserver/system-img/rootfs.tar.gz ../rootfs-builder/rootfs.tar.gz
	rm -f /_autoserver/system-img/rootfs.tar.gz

	docker rmi autoserver-rootfs
fi

T_ARCH=amd64 sh make-container.sh </dev/null
cp /_autoserver/_ctr-script-build-output_1/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_1_amd64.sqf
rm -rf /_autoserver/_ctr-script-build-output_1

docker rmi ctr-script-generic

T_ARCH=arm32 sh make-container.sh </dev/null
cp /_autoserver/_ctr-script-build-output_5/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_1_arm32.sqf
rm -rf /_autoserver/_ctr-script-build-output_5

docker rmi ctr-script-generic

T_ARCH=arm64 sh make-container.sh </dev/null
cp /_autoserver/_ctr-script-build-output_6/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_1_arm64.sqf
rm -rf /_autoserver/_ctr-script-build-output_6

docker rmi ctr-script-generic

sh make-container-2.sh </dev/null
cp /_autoserver/_ctr-script-build-output_2/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_2_amd64.sqf
rm -rf /_autoserver/_ctr-script-build-output_2

docker rmi ctr-script2-mediawiki ctr-script2-node

sh make-container-2-arm64.sh </dev/null
cp /_autoserver/_ctr-script-build-output_7/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_2_arm64.sqf
rm -rf /_autoserver/_ctr-script-build-output_7

docker rmi ctr-script7-mediawiki ctr-script7-node

sh make-container-2-arm32.sh </dev/null
cp /_autoserver/_ctr-script-build-output_8/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_2_arm32.sqf
rm -rf /_autoserver/_ctr-script-build-output_8

docker rmi ctr-script8-node
if [ "alt" = "$1" ]; then
	sh make-build-ctr.sh </dev/null
	cp /_autoserver/_ctr-script-build-output_9/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_5_amd64.sqf
	rm -rf /_autoserver/_ctr-script-build-output_9

	docker rmi ctr-script-build
else
	# sh make-throwaway.sh </dev/null
	# cp /_autoserver/_ctr-script-build-output_4/_output/mix-containers.squashfs /_autoserver_out/extra_container_modules/mix_4_amd64.sqf
	# rm -rf /_autoserver/_ctr-script-build-output_4

	# docker rmi ctr-script-throwaway
fi
