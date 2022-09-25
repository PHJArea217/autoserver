#!/bin/sh

set -eu
umask 022
mkdir -p /_autoserver
docker build -t ctr-script7-mediawiki - <<\EOF
FROM arm64v8/mediawiki:stable-fpm
RUN mv /var/www/html/extensions /var/www/html/extensions-builtin && mv /var/www/html/skins /var/www/html/skins-builtin && \
mkdir -p /var/www/html/extensions /var/www/html/skins /var/www/data && ln -s /ctr_local/LocalSettings.php /var/www/html
EOF

docker build -t ctr-script7-node - <<\EOF
FROM arm64v8/node:lts-slim
RUN npm install -g express ip axios ejs
EOF
# docker run --rm -v /_autoserver/_ctr-script-build-output_2/matrix-synapse:/build_out --entrypoint= -u root matrixdotorg/synapse /bin/sh -c 'tar c /bin /conf /etc /lib /lib64 /sbin /start.py /usr /var > /build_out/rootfs.tar'
docker run --rm -v /_autoserver/_ctr-script-build-output_7/mediawiki:/build_out --entrypoint= -u root ctr-script7-mediawiki /bin/sh -c 'tar c /bin /etc /lib /sbin /usr /var > /build_out/rootfs.tar'
docker run --rm -v /_autoserver/_ctr-script-build-output_7/node_js:/build_out --entrypoint= -u root ctr-script7-node /bin/sh -c 'tar c /bin /etc /lib /sbin /usr /var > /build_out/rootfs.tar'
# docker run --rm -v /_autoserver/_ctr-script-build-output_2/certbot:/build_out --entrypoint= -u root certbot/certbot /bin/sh -c 'tar c /bin /etc /lib /opt /sbin /usr /var > /build_out/rootfs.tar'
docker run --rm -v /_autoserver/_ctr-script-build-output_7/docker:/build_out --entrypoint= -u root arm64v8/docker:dind-rootless /bin/sh -c 'tar c /bin /etc /lib /opt /sbin /usr /var > /build_out/rootfs.tar'

. ./common
write_system 7 100000 aarch64
do_build_output 7 55567
