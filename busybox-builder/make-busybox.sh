#!/bin/sh
set -eu
docker build -t busybox-builder docker/

docker run --rm busybox-builder sh -c 'bsdtar -czf /output.tar.gz /output /_socketbox && cat /output.tar.gz' > busybox.tar.gz
docker run -i --rm busybox-builder sh > libs.tar.gz <<\EOF
set -eu
mkdir -p /_libs/i >&2
cp /sbin/ip /lib64/ld-linux-x86-64.so.2 /_libs/ >&2
for x in /sbin/ip /output/busybox-d; do
	setpriv --reuid=1000 --regid=1000 --clear-groups env LD_TRACE_LOADED_OBJECTS=1 "$x" | sed -n 's!^\t[^ ]* => /\(usr[^ ]*\|lib[^ ]*\) [()x0-9a-f ]*$!\1!p' | xargs -I{} cp -- {} /_libs/i/ >&2
done
bsdtar -czf /output.tar.gz /_libs && cat /output.tar.gz
EOF
