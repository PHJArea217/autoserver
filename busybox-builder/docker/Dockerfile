FROM debian:10
ARG bb_version=1.33.0
ARG bb_sha512=20f8f5197c5cbc8b244f69d82d6628066296c7306a9736ee1344cb555882854412cf7f264490f9a735251c139b9621004f48e972d06ef2623a3c99278f8e765a
RUN apt-get update && DEBIAN_FRONTEND=noninteractive sh -c 'apt-get -y dist-upgrade && apt-get install -y ca-certificates libarchive-tools build-essential gcc git make wget' && mkdir /output
RUN wget -O /busybox.tar.bz2 https://www.busybox.net/downloads/busybox-"$bb_version".tar.bz2 && sha512sum /busybox.tar.bz2 | grep -q "$bb_sha512"
# ADD *.c /output/

RUN mkdir -p /busybox-d && \
	bsdtar -xC /busybox-d -f /busybox.tar.bz2 --strip-components 1 && \
	printf 'CONFIG_%s=y\n' BASH_IS_ASH BBCONFIG FEATURE_UNIX_LOCAL PIE RFKILL \
	VERBOSE_RESOLUTION_ERRORS FEATURE_PREFER_APPLETS > /busybox-d/.config && \
	printf 'CONFIG_%s=n\n' FEATURE_PREFER_IPV4_ADDRESS FEATURE_SH_EXTRA_QUIET \
	>> /busybox-d/.config && \
	yes "" | make -C /busybox-d oldconfig && make -C /busybox-d -j 8 && \
	cp -ar --reflink=auto /busybox-d /busybox-s && \
	sed -i '/^#/d;/^CONFIG_PIE=/cCONFIG_PIE=n\nCONFIG_STATIC=y' /busybox-s/.config && \
	yes "" | make -C /busybox-s oldconfig && make -C /busybox-s -j 8 && \
	cp -a /busybox-d/busybox /output/busybox-d && \
	cp -a /busybox-s/busybox /output/busybox-s

RUN mkdir /c-s && cd /c-s && git clone https://git.peterjin.org/_/container-scripts && cd /c-s/container-scripts/utils && bsdtar -cJf /output/ctrtool-src.tar.xz . && make -j 4 && cp ctrtool /output/
# RUN for x in container-launcher reset_cgroup mini-init container-rootfs-mount; do gcc -o /output/"$x" /output/"$x".c && strip /output/"$x" && gzip -9 /output/"$x.c"; done
