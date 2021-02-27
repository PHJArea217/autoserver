#!/bin/sh

set -eu
umask 022
# docker build -t ctr-script3-owncloud - <<\EOF
# FROM owncloud/server
# RUN chmod 755 /var/www/owncloud/apps /var/www/owncloud/config && mkdir /var/www/owncloud/rwdisk && mkdir -p /var/www/owncloud/custom && mv /var/lib /var/_lib && mkdir /var/lib
# EOF

# docker run --rm -v /_ctr-script-build-output_3/owncloud:/build_out --entrypoint= -u root ctr-script3-owncloud /bin/sh -c 'tar -c /bin /etc /lib /lib64 /sbin /usr /var > /build_out/rootfs.tar'
docker run --rm -v /_ctr-script-build-output_3/guacamole:/build_out --entrypoint= -u root guacamole/guacamole /bin/sh -c 'mkdir -p /etc/guacamole && tar c /bin /etc /lib /lib64 /opt /sbin /usr /var > /build_out/rootfs.tar'
docker run --rm -v /_ctr-script-build-output_3/guacamole-guacd:/build_out --entrypoint= -u root guacamole/guacd /bin/sh -c 'tar c /bin /etc /lib /lib64 /sbin /usr /var > /build_out/rootfs.tar'

. ./common
do_build_output 3 55563
