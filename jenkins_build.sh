#!/bin/sh
set -e

. /vyos/pkg_scripts/env.sh

[ -e "/vyos/pkg_scripts/patches/$1/series" ] && QUILT_PATCHES="/vyos/pkg_scripts/patches/$1" quilt push -a

exec perl -I/vyos/pkg_scripts/perl5_lib /vyos/pkg_scripts/runjenkins.pl
