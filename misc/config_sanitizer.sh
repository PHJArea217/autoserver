#!/bin/sh
V=
if [ "$1" = "inverse" ]; then
	V=-v
fi
grep $V '# CONFIG_[A-Za-z0-9_]* is not set\|CONFIG_[A-Za-z0-9_]*=\([ymn]\|[0-9]\{,10\}\)'
