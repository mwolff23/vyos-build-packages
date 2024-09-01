#!/bin/sh
set -e

. /vyos/pkg_scripts/env.sh

sudo sh -c 'echo "deb file:///vyos/apt/pub/dev.packages.vyos.net sagitta main" >/etc/apt/sources.list.d/vyos-local.list'
sudo cp /vyos/apt/pubkey.asc /etc/apt/trusted.gpg.d/vyos-local.asc
sudo apt-get update

[ -e "/vyos/pkg_scripts/patches/$1/series" ] && QUILT_PATCHES="/vyos/pkg_scripts/patches/$1" quilt push -a

sudo mk-build-deps --install --tool "apt-get --yes --no-install-recommends"
exec dpkg-buildpackage -b -us -uc -tc
