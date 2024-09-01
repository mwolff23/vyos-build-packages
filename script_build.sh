#!/bin/sh
set -e

. /vyos/pkg_scripts/env.sh

[ -e "/vyos/pkg_scripts/patches/$1/series" ] && QUILT_PATCHES="/vyos/pkg_scripts/patches/$1" quilt push -a

[ -e ./build.sh ] || { echo "ERROR: build.sh not found"; exit 1; }

chmod +x ./build.sh
exec ./build.sh
