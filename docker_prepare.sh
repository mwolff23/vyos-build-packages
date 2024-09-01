#!/bin/sh
set -e

###
# prepare environment inside of docker container
###

# only allow to run in docker pipeline
[ -n "$VYOS_VOLUME" ] || exit 1
[ -e /.dockerenv ] || exit 1

if [ -n "$APT_PROXY" ]; then
  echo "Using Apt Proxy $APT_PROXY"
  printf 'Acquire::http::proxy "%s";\nAcquire::https::proxy "DIRECT";\n' "$APT_PROXY" >/etc/apt/apt.conf.d/99proxy
fi

apt-get update
apt-get install -y sudo docker.io aptly 7zip

chown node: /vyos
printf 'node ALL=(ALL) NOPASSWD: ALL\n' >/etc/sudoers.d/docker
chmod 0400 /etc/sudoers.d/docker

[ -n "$GITHUB_WORKSPACE" ] || exit 0
[ -e "$GITHUB_WORKSPACE/pkg_scripts" ] || exit 0

[ -e /vyos/pkg_scripts ] && rm -rf /vyos/pkg_scripts
sudo -u node cp -r "$GITHUB_WORKSPACE/pkg_scripts" "/vyos/pkg_scripts"
