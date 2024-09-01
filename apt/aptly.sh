#!/bin/sh
set -e

# make sure we run in docker
# since we modify files and don't want to break anything outside
[ -e /.dockerenv ] || exit 1

[ -n "$VYOS_VOLUME" ] || exit 1
docker_volume="$VYOS_VOLUME"
builddir="/vyos/pkg_build"
aptdir="/vyos/apt"

[ -x /usr/bin/aptly ] || { apt-get update; apt-get install -y aptly; }
[ -d "$aptdir" ] || mkdir -p "$aptdir"

vyosdist="equuleus"

if [ ! -e "$aptdir/.gnupg" ]; then
  keydetails="$(mktemp)"
  cat >"$keydetails" <<EOF
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 2048
Subkey-Type: RSA
Subkey-Length: 2048
Name-Real: root
Name-Email: root@localhost
Expire-Date: 0
%no-ask-passphrase
%no-protection
# Do a commit here, so that we can later print "done" :-)
%commit
%echo done
EOF
  gpg --homedir "$aptdir/.gnupg" --verbose --batch --full-generate-key "$keydetails"
  rm "$keydetails"
  gpg --homedir "$aptdir/.gnupg" --armor --export >"$aptdir/pubkey.asc"
fi

rm -rf "$HOME/.gnupg"
cp -r "$aptdir/.gnupg" "$HOME/.gnupg"

if [ ! -e "$aptdir/aptly.conf" ]; then
  cp "/vyos/pkg_scripts/apt/aptly.conf" "$aptdir/aptly.conf"

  aptly -config="$aptdir/aptly.conf" repo create -architectures="amd64" "vyos-${vyosdist}"
  aptly -config="$aptdir/aptly.conf" publish repo -architectures="amd64" -distribution="${vyosdist}" -origin="dev.packages.vyos.net" -label="VyOS 1.4 development repository" "vyos-${vyosdist}" filesystem:apt:dev.packages.vyos.net
fi

tmpfile="$(mktemp)"
find /vyos/pkg_build/ /vyos/pkg_build/vyos-build/packages \
  -maxdepth 2 -type f -iname '*.deb' -not -iname '*-build-deps_*' -print0 >"$tmpfile"

# exit if no new packages found
[ "$(grep -cz '^' "$tmpfile")" -eq 0 ] && { rm -f "$tmpfile"; exit 0; }

xargs -0r aptly -config="$aptdir/aptly.conf" repo add -remove-files -force-replace "vyos-${vyosdist}" <"$tmpfile"

aptly -config="$aptdir/aptly.conf" publish update "${vyosdist}" filesystem:apt:dev.packages.vyos.net >"$tmpfile" 2>&1 || { cat "$tmpfile"; exit 1; }

rm -f "$tmpfile"
