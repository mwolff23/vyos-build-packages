#!/bin/sh
set -e

. /vyos/pkg_scripts/env.sh

[ -e "/vyos/pkg_scripts/patches/$1/series" ] && QUILT_PATCHES="/vyos/pkg_scripts/patches/$1" quilt push -a

sudo apt-get update
sudo mk-build-deps --install --tool "apt-get --yes --no-install-recommends"
exec dpkg-buildpackage -b -us -uc -tc
