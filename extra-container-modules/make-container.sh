#!/bin/sh

set -eu
umask 022
mkdir -p /_autoserver
# docker build -t ctr-script-matrix-synapse - <<\EOF
# FROM ubuntu:20.04
# RUN apt-get update && apt-get -y dist-upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends wget apt-transport-https ca-certificates
# RUN mkdir /usr/local/share/keyrings_b && wget -O /usr/local/share/keyrings_b/matrix.gpg \
# 	https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg && \
# 	printf 'deb [signed-by=/usr/local/share/keyrings_b/matrix.gpg] https://packages.matrix.org/debian/ focal main\n' \
# 	> /etc/apt/sources.list.d/matrix.list
# RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends matrix-synapse-py3
# EOF

BASE_IMAGE=debian:11
GITEA_ARCH=amd64
FILE_ARCH=amd64
NR=1
case "$T_ARCH" in
	arm32)
		BASE_IMAGE=arm32v7/debian:11
		GITEA_ARCH=arm-6
		FILE_ARCH=arm32
		NR=5
		;;
	arm64)
		BASE_IMAGE=arm64v8/debian:11
		GITEA_ARCH=arm64
		FILE_ARCH=aarch64
		NR=6
		;;
esac

GITEA_VERSION='1.18.3'

mkdir -p tmp
# cp /usr/bin/qemu-arm-static /usr/bin/qemu-aarch64-static tmp/
cat > tmp/Dockerfile <<EOF
FROM $BASE_IMAGE
# COPY qemu-arm-static qemu-aarch64-static /usr/bin/
RUN apt-get update && apt-get -y dist-upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends wget apt-transport-https ca-certificates && \\
sed -i 's# http://# https://#g' /etc/apt/sources.list && apt-get update && apt-get -y dist-upgrade

# RUN dpkg-divert --add --no-rename /usr/bin/qemu-arm-static && dpkg-divert --add --no-rename /usr/bin/qemu-aarch64-static

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apt-utils htop less strace nginx-extras fcgiwrap apache2 python3 haproxy \\
postfix dovecot-imapd fetchmail spamassassin busybox-static default-mysql-client default-mysql-server libapache2-mod-php php-fpm inotify-tools \\
pulseaudio php-gd php-imagick php-intl php-json php-mbstring php-mysql php-pgsql php-sqlite3 php-xml php-zip libsasl2-modules \\
qemu-user-static $([ "amd64" = "$GITEA_ARCH" ] && echo qemu-system-x86 || :) opendkim opendkim-tools geoip-database gnupg libfcgi-bin ovmf dnsmasq-base unbound \\
qemu-utils sa-compile shared-mime-info spamc curl cgit python3-markdown python3-pygments rsyslog iptables wireguard-tools \\
postfix-pcre iproute2 pdns-server pdns-backend-sqlite3 pdns-backend-remote acl net-tools ntp sqlite3 && \\
rm -rf /etc/ssl/private /etc/unbound/*.pem /etc/unbound/*.key /etc/ssl/certs/ca-certificates.crt /etc/docker/key.json \\
/etc/ssl/certs/ssl-cert-snakeoil.pem && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure ca-certificates

RUN c_rehash /etc/ssl/certs && mkdir -p /lib64 && \\
	update-alternatives --set iptables /usr/sbin/iptables-nft && \\
	update-alternatives --set ip6tables /usr/sbin/ip6tables-nft

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends php-ctype php-curl \\
php-dom php-iconv php-phar php-posix php-simplexml php-xmlwriter screen tmux

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssh-server openssh-client \\
openssh-sftp-server git bind9 bind9utils dnsutils libarchive-tools xz-utils && rm -rf /etc/ssh/ssh_host_* /etc/bind/rndc.key

RUN wget -O /gitea.xz https://dl.gitea.io/gitea/"$GITEA_VERSION"/gitea-"$GITEA_VERSION"-linux-"$GITEA_ARCH".xz && \\
	mkdir /extras && \\
	xzcat /gitea.xz > /extras/gitea.bin && \\
	chmod +x /extras/gitea.bin && \\
	rm -f /gitea.xz

RUN set -eu; for x in apache2 dovecot mysql nginx php postfix spamassassin; do mv "/etc/\$x" "/etc/_\${x}" && ln -s "/ctr_local/\$x" /etc/"\$x"; done; mv /usr/local /usr/_local && mkdir /usr/local && rm -rf /var/lib/mysql /var/lib/nginx && mkdir /var/lib/mysql /var/lib/nginx
EOF

docker build -t ctr-script-generic tmp/

# docker run --rm -v /_autoserver/_ctr-script-build-output_1/matrix-synapse:/build_out --entrypoint= -u root ctr-script-matrix-synapse /bin/sh -c 'tar c /bin /etc /lib /lib64 /opt /sbin /usr /var > /build_out/rootfs.tar'
docker run --rm -v /_autoserver/_ctr-script-build-output_"$NR"/generic:/build_out --entrypoint= -u root ctr-script-generic /bin/sh -c 'tar c /bin /etc /extras /lib /lib64 /opt /sbin /usr /var > /build_out/rootfs.tar'

. ./common
write_system "$NR" 100000 "$FILE_ARCH"
do_build_output "$NR" 55561
