#!/bin/sh
set -e

pkgdir="$1"

[ -e "${pkgdir}/.xcp-ng" ] && exit 0

tmpdir=$(mktemp -d)
cd "$tmpdir"

wget -q -O"xcp-ng-pv-tools.rpm" "http://mirrors.xcp-ng.org/8/8.2/base/x86_64/Packages/xcp-ng-pv-tools-8.2.0-2.xcpng8.2.noarch.rpm"

7zz x "xcp-ng-pv-tools.rpm"
rm "xcp-ng-pv-tools.rpm"

7zz x xcp-ng-pv-tools-8.2.0-2.xcpng8.2.noarch.cpio ./opt/xensource/packages/iso/guest-tools-8.2.0-2.xcpng8.2.iso
7zz x ./opt/xensource/packages/iso/guest-tools-8.2.0-2.xcpng8.2.iso Linux/xe-guest-utilities_7.20.0-1_amd64.deb
cp -v Linux/xe-guest-utilities_7.20.0-1_amd64.deb "$pkgdir"

cd /tmp
rm -rf "$tmpdir"

touch "${pkgdir}/.xcp-ng"
