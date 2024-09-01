#!/bin/sh
set -e

basedir="$(readlink -f .)"

if [ -n "$VYOS_VOLUME" ]; then
  # required for git pipeline
  [ "$(id -u)" -eq 0 ] && exec sudo --preserve-env=VYOS_VOLUME -u node -- "$0" "$@"
  # persistent volume for /vyos
  docker_volume="$VYOS_VOLUME"
  builddir="/vyos/pkg_build"
  dockercmd="sudo docker"
else
  docker_volume="$basedir"
  builddir="$basedir/pkg_build"
  dockercmd="docker"
fi

# some package builds will fail as root
[ "$(id -u)" -eq 0 ] && { echo "don't run me as root!!!"; exit 1; }

[ -t 0 ] && dockerrunopts="-ti"

[ -d "$builddir" ] || mkdir "$builddir"
cd "$builddir"

logtmp="$(mktemp)"

vyosdist="sagitta"
dockerimage="vyos/vyos-build:$vyosdist"

# build debian package from external repo
vybuilddeb_ext() {
  pkgname="$1"
  branch="$2"
  [ -n "$branch" ] || branch="$vyosdist"
  buildscript="$3"
  [ -n "$buildscript" ] || buildscript="/vyos/pkg_scripts/deb_build.sh"
  pkgurl="$4"
  [ -n "$pkgurl" ] || pkgurl="https://github.com/vyos/$pkgname.git"

  [ -e "$builddir/$pkgname/.build" ] && return

  [ -e "$builddir/$pkgname" ] || git clone --branch "$branch" "$pkgurl" "$builddir/$pkgname"
  echo "BUILDING PACKAGE $pkgname"

  $dockercmd run $dockerrunopts --rm --privileged -v "${docker_volume}:/vyos" -w "/vyos/pkg_build/$pkgname" \
    --sysctl net.ipv6.conf.lo.disable_ipv6=0 "$dockerimage" "$buildscript" "$pkgname" >"$logtmp" 2>&1 \
  || { cat "$logtmp"; exit 1; }

  touch "$builddir/$pkgname/.build"
}

[ -e "$builddir/vyos-build" ] || \
git clone --depth 1 --branch "$vyosdist" https://github.com/vyos/vyos-build.git "$builddir/vyos-build"

###
# find all vyos-build packages
##
cd "$builddir/vyos-build/packages"
rm -f "packages.txt"
for pkgname in *; do
  [ -e "$pkgname/Jenkinsfile" ] || continue
  case $pkgname in
    pam_tacplus)
      # not used by official sagitta build either
      # use vyos/libpam-tacplus instead
      continue
    ;;
  esac
  echo "$pkgname" >>"packages.txt"
done

###
# use jenkins wrapper for vyos-build packages
##
for pkgname in $(cat "$builddir/vyos-build/packages/packages.txt"); do
  [ -e "$builddir/vyos-build/packages/$pkgname/.build" ] && continue
  echo "BUILDING PACKAGE vyos-build/$pkgname"

  $dockercmd run $dockerrunopts --rm --privileged -v "${docker_volume}:/vyos" -w "/vyos/pkg_build/vyos-build/packages/$pkgname" \
    --sysctl net.ipv6.conf.lo.disable_ipv6=0 "$dockerimage" \
    /vyos/pkg_scripts/jenkins_build.sh "$pkgname" >"$logtmp" 2>&1 \
  || { cat "$logtmp"; exit 1; }

  touch "$builddir/vyos-build/packages/$pkgname/.build"
done

vybuilddeb_ext live-boot
vybuilddeb_ext vyos-user-utils
vybuilddeb_ext vyos-http-api-tools
vybuilddeb_ext vyos-utils
vybuilddeb_ext libvyosconfig
vybuilddeb_ext vyos-xe-guest-utilities current
vybuilddeb_ext vyatta-biosdevname
vybuilddeb_ext ipaddrcheck
vybuilddeb_ext hvinfo
vybuilddeb_ext udp-broadcast-relay
vybuilddeb_ext libpam-radius-auth
vybuilddeb_ext libtacplus-map master
vybuilddeb_ext libnss-mapuser
vybuilddeb_ext vyos-cloud-init '' "/vyos/pkg_scripts/script_build.sh"
vybuilddeb_ext iproute2 '' "/vyos/pkg_scripts/script_build.sh" "https://github.com/mwolff23/vyos-iproute2.git"

# vyos-world and dependencies
vybuilddeb_ext vyos-world
"$basedir/pkg_scripts/debcontrol_depends.pl" "$builddir/vyos-world" vyos-world >"$builddir/world_packages.txt"
for i in $(cat "$builddir/world_packages.txt"); do
  vybuilddeb_ext "$i"
done

"$basedir/pkg_scripts/apt/aptly.sh"

# build using our own apt repo and previously build packages
vybuilddeb_ext libpam-tacplus '' "/vyos/pkg_scripts/deb_build_vyosrepo.sh"
"$basedir/pkg_scripts/apt/aptly.sh"
vybuilddeb_ext libnss-tacplus master "/vyos/pkg_scripts/deb_build_vyosrepo.sh"

if [ -n "$VYOS_BUILDEXT" ]; then
  for i in $VYOS_BUILDEXT; do
     [ -e "$basedir/pkg_scripts/external/$i.sh" ] || \
      { echo "WARNING: no external package build script for '$i' found. Skipping."; continue; }

    "$basedir/pkg_scripts/external/$i.sh" "$builddir"
  done
fi

"$basedir/pkg_scripts/apt/aptly.sh"

exit 0
