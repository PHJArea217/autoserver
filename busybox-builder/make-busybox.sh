#!/bin/sh
set -eu
docker build -t busybox-builder docker/

docker run --rm busybox-builder sh -c 'bsdtar -czf /output.tar.gz /output && cat /output.tar.gz' > busybox.tar.gz
