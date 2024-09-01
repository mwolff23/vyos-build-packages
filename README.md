# VyOS Package Build

Generates all packages to build a complete sagitta image from scratch.


## build.sh
Triggers build of all packages and creates apt repository

# Package build helpers

## jenkins_build.sh
Wrapper to build from Jenkinsfile without Jenkins

## deb_build.sh
Generic Debian package build

## deb_build_vyosrepo.sh
Debian package build with dependencies from local vyos repository

## script_build.sh
Build with `build.sh` script
