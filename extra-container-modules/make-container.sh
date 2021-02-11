#!/bin/sh

set -eu
umask 022

docker build -t ctr-script-matrix-synapse - <<\EOF
FROM ubuntu:20.04
RUN apt-get update && apt-get -y dist-upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends wget apt-transport-https ca-certificates
RUN mkdir /usr/local/share/keyrings_b && wget -O /usr/local/share/keyrings_b/matrix.gpg \
	https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg && \
	printf 'deb [signed-by=/usr/local/share/keyrings_b/matrix.gpg] https://packages.matrix.org/debian/ focal main\n' \
	> /etc/apt/sources.list.d/matrix.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends matrix-synapse-py3
EOF

docker build -t ctr-script-generic - <<\EOF
FROM ubuntu:20.04
RUN apt-get update && apt-get -y dist-upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends wget apt-transport-https ca-certificates
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nginx-extras fcgiwrap apache2 python3 \
postfix dovecot-imapd fetchmail spamassassin busybox-static mysql-client mysql-server libapache2-mod-php php-fpm \
php-gd php-imagick php-intl php-json php-mbstring php-mysql php-sqlite3 php-xml php-zip \
qemu-system-x86 qemu-user-static opendkim opendkim-tools geoip-database gnupg libfcgi-bin ovmf \
qemu-utils sa-compile shared-mime-info spamc
RUN set -eu; for x in apache2 dovecot mysql nginx php postfix spamassassin; do mv "/etc/$x" "/etc/_${x}" && ln -s "/host_config/$x" /etc/"$x"; done; mv /usr/local /usr/_local && mkdir /usr/local && rm -rf /var/lib/mysql /var/lib/nginx && mkdir /var/lib/mysql /var/lib/nginx
EOF

docker run --rm -v /_ctr-script-build-output_1/matrix-synapse:/build_out --entrypoint= -u root ctr-script-matrix-synapse /bin/sh -c 'tar c /bin /etc /lib /lib64 /opt /sbin /usr /var > /build_out/rootfs.tar'
docker run --rm -v /_ctr-script-build-output_1/generic:/build_out --entrypoint= -u root ctr-script-generic /bin/sh -c 'tar c /bin /etc /lib /lib64 /opt /sbin /usr /var > /build_out/rootfs.tar'

. ./common
write_system 1 100000
do_build_output 1 55561
