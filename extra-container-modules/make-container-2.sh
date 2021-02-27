#!/bin/sh

set -eu
umask 022
docker build -t ctr-script2-mediawiki - <<\EOF
FROM mediawiki:stable-fpm
RUN mv /var/www/html/extensions /var/www/html/extensions-builtin && mv /var/www/html/skins /var/www/html/skins-builtin && \
mkdir -p /var/www/html/extensions /var/www/html/skins /var/www/data && ln -s /ctr_local/LocalSettings.php /var/www/html
EOF

# docker build -t ctr-script2-gitea - <<\EOF
# FROM debian:10
# RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends openssh-server git ca-certificates wget bind9 bind9utils && rm -f /etc/ssh/ssh_host* && mv /etc/ssh /etc/_ssh && mkdir /etc/ssh
# RUN wget -O /usr/local/bin/gitea https://dl.gitea.io/gitea/1.13.1/gitea-1.13.1-linux-amd64 && chmod +x /usr/local/bin/gitea
# EOF

# docker run --rm -v /_ctr-script-build-output_2/gitea:/build_out --entrypoint= -u root ctr-script2-gitea /bin/sh -c 'tar c /bin /etc /lib /lib64 /sbin /usr /var > /build_out/rootfs.tar'
docker run --rm -v /_ctr-script-build-output_2/matrix-synapse:/build_out --entrypoint= -u root matrixdotorg/synapse /bin/sh -c 'tar c /bin /conf /etc /lib /lib64 /sbin /start.py /usr /var > /build_out/rootfs.tar'
docker run --rm -v /_ctr-script-build-output_2/mediawiki:/build_out --entrypoint= -u root ctr-script2-mediawiki /bin/sh -c 'tar c /bin /etc /lib /lib64 /sbin /usr /var > /build_out/rootfs.tar'
docker run --rm -v /_ctr-script-build-output_2/node_js:/build_out --entrypoint= -u root node:lts-slim /bin/sh -c 'tar c /bin /etc /lib /lib64 /sbin /usr /var > /build_out/rootfs.tar'
docker run --rm -v /_ctr-script-build-output_2/certbot:/build_out --entrypoint= -u root certbot/certbot /bin/sh -c 'tar c /bin /etc /lib /opt /sbin /usr /var > /build_out/rootfs.tar'

. ./common
write_system 2 100000
do_build_output 2 55562
