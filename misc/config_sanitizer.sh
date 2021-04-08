#!/bin/sh
sed '/^\(# CONFIG_[A-Za-z0-9_]* is not set\|CONFIG_[A-Za-z0-9_]*=\([ymn]\|[0-9]\{,10\}\)\)$/d'
