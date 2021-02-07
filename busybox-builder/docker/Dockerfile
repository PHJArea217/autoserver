FROM debian:10
ARG bb_version=1.33.0
ARG bb_sha512=20f8f5197c5cbc8b244f69d82d6628066296c7306a9736ee1344cb555882854412cf7f264490f9a735251c139b9621004f48e972d06ef2623a3c99278f8e765a
RUN apt-get update && DEBIAN_FRONTEND=noninteractive sh -c 'apt-get -y dist-upgrade && apt-get install -y ca-certificates libarchive-tools build-essential gcc git make wget'
RUN wget -O /busybox.tar.bz2 https://www.busybox.net/downloads/busybox-"$bb_version".tar.bz2 && sha512sum /busybox.tar.bz2 | grep -q "$bb_sha512"
# ADD *.c /output/

ADD busybox-cmd /root/

RUN mkdir /output /build && \
	adduser --system --group --no-create-home build-user && \
	chown build-user:build-user /build && \
	setpriv --no-new-privs --reuid=build-user --regid=build-user --clear-groups sh -s < /root/busybox-cmd && \
	setpriv --no-new-privs --reuid=build-user --regid=build-user --clear-groups cat /build/busybox-d/busybox > /output/busybox-d && \
	setpriv --no-new-privs --reuid=build-user --regid=build-user --clear-groups cat /build/busybox-s/busybox > /output/busybox-s && \
	chmod +x /output/busybox-d /output/busybox-s

RUN mkdir /c-s && cd /c-s && chown build-user:build-user /c-s && \
	setpriv --no-new-privs --reuid=build-user --regid=build-user --clear-groups \
	sh -c 'set -Ce && git clone https://git.peterjin.org/_/container-scripts && cd /c-s/container-scripts/utils && bsdtar -cJf - > /build/ctrtool-src.tar.xz . && make -j 4 && strip ctrtool -o /build/ctrtool' && \
	cp /build/ctrtool /build/ctrtool-src.tar.xz /output/

RUN mkdir /socketbox /_socketbox && cd /socketbox && chown build-user:build-user /socketbox && \
	setpriv --no-new-privs --reuid=build-user --regid=build-user --clear-groups \
	sh -c 'set -Ce && git clone --no-checkout https://git.peterjin.org/_/socketbox && cd socketbox && bsdtar -cJf - > /build/socketbox-src.tar.xz . && git reset --hard && make -j 4 && strip libsocketbox-preload.so send-receive-fd socket-query socketbox socketbox-inetd socketbox-relay' && \
	cd socketbox && cp libsocketbox-preload.so send-receive-fd socket-query socketbox socketbox-inetd socketbox-relay /build/socketbox-src.tar.xz /_socketbox/

# RUN for x in container-launcher reset_cgroup mini-init container-rootfs-mount; do gcc -o /output/"$x" /output/"$x".c && strip /output/"$x" && gzip -9 /output/"$x.c"; done
