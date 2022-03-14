#!/bin/sh

set -eu
umask 022
mkdir -p /_autoserver

docker build -t ctr-script8-node - <<\EOF
FROM arm32v7/node:lts-slim
RUN npm install -g express ip axios
EOF
docker run --rm -v /_autoserver/_ctr-script-build-output_8/node_js:/build_out --entrypoint= -u root ctr-script8-node /bin/sh -c 'tar c /bin /etc /lib /sbin /usr /var > /build_out/rootfs.tar'

. ./common
write_system 8 100000 arm32
do_build_output 8 55568
