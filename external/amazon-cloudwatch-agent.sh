#!/bin/sh
set -e

pkgdir="$1"

[ -e "${pkgdir}/.amazon-cloudwatch-agent" ] && exit 0
[ -e "${pkgdir}/amazon-cloudwatch-agent.deb" ] && exit 0

wget -q -O"${pkgdir}/amazon-cloudwatch-agent.deb" "https://amazoncloudwatch-agent.s3.amazonaws.com/debian/amd64/latest/amazon-cloudwatch-agent.deb"

touch "${pkgdir}/.amazon-cloudwatch-agent"
